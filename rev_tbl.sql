IF EXISTS (SELECT * FROM sysobjects
           WHERE  name = 'sp__revtable'
           AND    type = 'P')
   DROP PROC sp__revtable

go

CREATE PROC sp__revtable(@objname char(50)=NULL)
AS

BEGIN
SET NOCOUNT ON
DECLARE @type   smallint              /* the object type */
DECLARE @objid int
DECLARE @cnt int, @status tinyint, @buffer varchar(70)
DECLARE @fldname char(50),@maxcnt int,@prec int, @scale int
DECLARE @troole varchar(70), @roole varchar(50)
DECLARE @msg varchar(255)

IF @objname IS NULL
BEGIN
  SELECT convert(varchar(70), 'Usage: sp__revtable @objname')
    return -1 
END

SELECT  @objid=object_id(@objname)
IF @objid IS NULL
BEGIN
  SELECT convert(varchar(70), 'Object '+@objname+' Not Found')
    return -1 
END

CREATE TABLE #tmp2 ( row_id int, roole  varchar(70))
CREATE TABLE #tmp ( row_id int, tbl_txt varchar(70) )
INSERT #tmp values (-1,'CREATE TABLE  '+@objname)
INSERT #tmp values ( 0,'(')
SELECT @cnt=1
SELECT @maxcnt=count(*) FROM syscolumns c WHERE c.id = @objid

WHILE 1=1
BEGIN 
    SELECT 
        /* output is c.name for n characters */
        @buffer=c.name + ' ' + t.name + substring('(' + convert(varchar(3),c.length) + ')',
            1, 6 * (charindex(t.name, 'varchar/varbinary'))),
           @scale  = c.scale,
        @prec      = c.prec,
        @fldname= t.name,
        @status = c.status,
        @type = c.type ,
                @roole =  ISNULL(OBJECT_NAME(c.domain),'None')
    FROM syscolumns c, systypes t 
        WHERE c.id = @objid
        and c.usertype *= t.usertype
        and colid=@cnt

    IF @@rowcount = 0 break
        IF @roole != 'None'
           BEGIN
             SELECT @troole = 'ALTER TABLE ' + rtrim(@objname) + ' ADD '+
                              rtrim(m.text)
             FROM sysconstraints c, sysobjects o, syscomments m
             WHERE c.tableid = object_id(@objname)
               AND o.id       = object_id(@roole)
               AND c.constrid = o.id
               AND o.id = m.id
               AND (o.sysstat & 15 = 7)

                 if( @troole is not null)
                 INSERT INTO #tmp2 VALUES (@cnt, @troole)

           END

    IF @fldname = 'numeric'
      BEGIN
         SELECT @buffer=rtrim(@buffer) + '(' + convert(varchar(3),@prec) 
        IF @scale > 0
        SELECT @buffer=rtrim(@buffer) +',' + convert(varchar(3),@scale) 
        SELECT @buffer=rtrim(@buffer) + ')'
      END

    IF @fldname = 'decimal'
      BEGIN
         SELECT @buffer=rtrim(@buffer) + '(' + convert(varchar(3),@prec) + ')'
      END

    IF (@fldname != 'bit' AND @status & 0x80 != 0)
       SELECT @buffer = rtrim(@buffer) + ' identity' 

    IF (@fldname != 'bit' AND @status & 8 != 0)
       SELECT @buffer = rtrim(@buffer) + ' NULL' 
        ELSE 
         SELECT @buffer = rtrim(@buffer) + ' NOT NULL' 
    IF @cnt < @maxcnt 
         SELECT @buffer = rtrim(@buffer) + ',' 

    INSERT #tmp values (@cnt,@buffer)

    SELECT @cnt=@cnt+1
END

INSERT #tmp values (@cnt,')')
SELECT @cnt=@cnt+1
SELECT  @objid=object_id(@objname)
select	@msg = s.name
from	sysindexes i,
		syssegments s
where	i.id = @objid
and		indid in (0,1)
and		i.segment = s.segment

if @msg = 'default'
	select	@msg = '''default'''

select	@msg = 'on ' + @msg

INSERT #tmp values (@cnt,@msg)

INSERT #tmp ( row_id, tbl_txt ) SELECT 100+row_id, roole FROM #tmp2

SELECT tbl_txt FROM #tmp ORDER BY row_id
DROP TABLE #tmp
DROP TABLE #tmp2

END

select 'alter table '+name+' lock '+case (o.sysstat2 & 57344) when 8192 then 'allpages' when 16384 then 'datapages' when 32768 then 'datarows' end 
from sysobjects o
where id = @objid

DECLARE @keys varchar(200)              /* string to build up index key in */
DECLARE @colcnt int, @cnt2 tinyint
DECLARE @clust int, @nonclust int       /* flag if clust/non-clust index */
DECLARE @pmytabid  int                  /* flag/id of referencing table */
DECLARE @reftabid int,  @constrid int 
DECLARE @indstat   int                  /* status of sysindexes  */
DECLARE @indstat2  int                  /* status2 of sysindexes */
DECLARE @keycnt int
DECLARE @indexid int
DECLARE @inddesc varchar(120)           /* string to build up index desc in */

SELECT @keys = ''
SELECT  @colcnt = 0
SELECT  @colcnt = id,                   /* Flag for row in sysobjects found */
        @clust    = (sysstat  & 16),    /* Flag for clustered index */
        @nonclust = (sysstat  & 32),    /* Flag for non-clustered index */
        @constrid = ckfirst,            /* Flag for table check constraint */
        @keycnt   = (sysstat2 & 4),     /* Flag for > 1 table check constr */
        @pmytabid = (sysstat2 & 2),     /* Flag for foreign key constraint */
        @reftabid = (sysstat2 & 1)      /* Flag for referenced table constr*/
FROM sysobjects
WHERE id = object_id(@objname)

IF (@colcnt = 0)
BEGIN
        /* 17461, 'Object does not exist in this database.' */
        exec sp_getmessage 17461, @msg out 
        print @msg 
        return (1) 
END     
/*    Get number of columns in this table. */
SELECT @colcnt = count(*)
FROM syscolumns
WHERE id = object_id(@objname)

/*    Check if no columns have any constraints or default */
IF (@colcnt = (SELECT count(*)
               FROM syscolumns
               WHERE id = object_id(@objname)
               AND domain = 0       /* No column check constraint */
               AND cdefault = 0))   /* No defaults */
   BEGIN              
     SELECT @colcnt = 0
   END     

/*
**  If no constraints on this table, return.
*/
IF (@clust = 0                  /* No clustered index */
    AND @nonclust = 0           /* No non-clustered index */
    AND @constrid = 0           /* No table check constraints */
    AND @pmytabid = 0           /* No foreign key constraints */
    AND @reftabid = 0           /* No references to this table */
    AND @colcnt   = 0)          /* No column default or check constraints */
BEGIN
  /* 18024, 'Object does not have any constraints.' */
  EXEC sp_getmessage 18024, @msg out 
  PRINT @msg
END
ELSE
BEGIN     
SELECT @cnt = COUNT(*), @cnt2 = 0
FROM   sysindexes
WHERE  id = object_id(@objname)
AND indid > 0
AND status2 & 2 = 2
IF @cnt > 0
   CREATE TABLE #inddesc
   ( pkdesc    varchar(120))

WHILE  @cnt2 < @cnt
BEGIN 
  SELECT  @indexid=i.indid, @indstat=i.status, @indstat2=i.status2, @keycnt=i.keycnt
   FROM   sysindexes i
   WHERE  id = object_id(@objname)
   AND indid > 0
   AND status2 & 2 = 2
	
   IF @@rowcount = 0 break
      /*
      **  First we'll figure out what the keys are.
      */
      DECLARE @i int
      DECLARE @thiskey varchar(50)

      SELECT @keys = '', @i = 1

      WHILE @i <= @keycnt
    
       BEGIN
         SELECT @thiskey = index_col(@objname, @indexid, @i)
                
         IF @thiskey IS NULL
         BEGIN
          GOTO keysdone
         END     
         IF @i > 1
         BEGIN
            SELECT @keys = @keys + ', '
         END     
                        
         SELECT @keys = @keys + index_col(@objname, @indexid, @i)
                       
         /*
         **  Increment @i so it will check for the next key.
         */
         SELECT @i = @i + 1
       END     
keysdone:
        SELECT @inddesc = 'ALTER TABLE '+ rtrim(@objname)  +' ADD '
                
        /*      
        ** Check if we have a PRIMARY KEY constraint or a UNIQUE constraint
        ** Note that we are only dealing with declarative indexes
        */
        IF (@indstat & 2048 = 2048)
        BEGIN
          SELECT @inddesc = @inddesc + ' PRIMARY KEY '
        END     
        ELSE    
        BEGIN
          SELECT @inddesc = @inddesc + ' UNIQUE '
        END     
                
        /*
        **  clustered or nonclustered index
        **  Note that the system by default creates an index
        */
        IF @indexid = 1
        BEGIN
          SELECT @inddesc = @inddesc + ' CLUSTERED '
        END     
        IF @indexid > 1
        BEGIN
          SELECT @inddesc = @inddesc + ' NONCLUSTERED '
        END     
        /*      
        **  Get the keys involved in the declarative constraint
        */
        SELECT @inddesc = @inddesc + ' (' + @keys + ')'
        
        /*
        **  Display if this key is referenced by other table
        */
        IF (@indstat2 & 1 = 1)
        BEGIN
          SELECT @inddesc = @inddesc + ', FOREIGN REFERENCE'
        END     
        
        INSERT #inddesc VALUES ( @inddesc )
        SELECT @cnt2 = @cnt2 + 1

END
IF @cnt > 0
SELECT RTRIM(pkdesc) FROM #inddesc

/**************************************/
DECLARE @cnstrname varchar(50)
DECLARE @foreign_keys varchar(125)
DECLARE @refrncd_keys varchar(125)
DECLARE @frgntab varchar(50), @pmrytab varchar(50)
DECLARE @propt   varchar(10)    /* print option :
                                ** 'detail' - full print
                                ** not supplied or otherwise - terse print */

SELECT @propt = 'terse'  

/* Declarations for sysreferences table cursor fetch */
DECLARE @fokey1 int,  @fokey2 int,  @fokey3 int,  @fokey4 int,  @fokey5  int
DECLARE @fokey6 int,  @fokey7 int,  @fokey8 int,  @fokey9 int,  @fokey10 int
DECLARE @fokey11 int, @fokey12 int, @fokey13 int, @fokey14 int, @fokey15 int
DECLARE @refkey1 int, @refkey2 int, @refkey3 int, @refkey4 int, @refkey5  int
DECLARE @refkey6 int, @refkey7 int, @refkey8 int, @refkey9 int, @refkey10 int
DECLARE @refkey11 int, @refkey12 int, @refkey13 int, @refkey14 int
DECLARE @refkey15 int, @refkey16 int, @fokey16 int
DECLARE @frgndbid int, @pmrydbid int, @tableid int
DECLARE @frgndbname varchar(50), @pmrydbname varchar(50)


CREATE TABLE  #spconstrtab (
       constraint_id    int,
       constraint_name  varchar(50),
       constraint_colno int,
       constraint_ermsg int,
       constraint_type  varchar(25),
       constraint_msg   varchar(255) null,
       constraint_desc  varchar(255) null)

SELECT @cnt = COUNT(*), @cnt2 = 0
FROM   sysreferences
WHERE  tableid  = object_id(@objname)
   OR  reftabid = object_id(@objname)
IF @cnt > 0
BEGIN
   CREATE TABLE  #t_sysreferences 
 (                                                                      
  /* indexid     smallint               NOT NULL,   */
  constrid    int                    NOT NULL,                          
  tableid     int                    NOT NULL,                          
  reftabid    int                    NOT NULL,                          
  keycnt      smallint               NOT NULL,                          
  status      smallint               NOT NULL,                          
  frgndbid    smallint               NOT NULL,                          
  pmrydbid    smallint               NOT NULL,                          
  /* spare2      int                    NOT NULL, */
  fokey1      tinyint                NOT NULL,                          
  fokey2      tinyint                NOT NULL,                          
  fokey3      tinyint                NOT NULL,                          
  fokey4      tinyint                NOT NULL,                          
  fokey5      tinyint                NOT NULL,                          
  fokey6      tinyint                NOT NULL,                          
  fokey7      tinyint                NOT NULL,                          
  fokey8      tinyint                NOT NULL,                          
  fokey9      tinyint                NOT NULL,                          
  fokey10     tinyint                NOT NULL,                          
  fokey11     tinyint                NOT NULL,                          
  fokey12     tinyint                NOT NULL,                          
  fokey13     tinyint                NOT NULL,                          
  fokey14     tinyint                NOT NULL,                          
  fokey15     tinyint                NOT NULL,                          
  fokey16     tinyint                NOT NULL,                          
  refkey1     tinyint                NOT NULL,                          
  refkey2     tinyint                NOT NULL,                          
  refkey3     tinyint                NOT NULL,                          
  refkey4     tinyint                NOT NULL,                          
  refkey5     tinyint                NOT NULL,                          
  refkey6     tinyint                NOT NULL,                          
  refkey7     tinyint                NOT NULL,                          
  refkey8     tinyint                NOT NULL,                          
  refkey9     tinyint                NOT NULL,                          
  refkey10    tinyint                NOT NULL,                          
  refkey11    tinyint                NOT NULL,                          
  refkey12    tinyint                NOT NULL,                          
  refkey13    tinyint                NOT NULL,                          
  refkey14    tinyint                NOT NULL,                          
  refkey15    tinyint                NOT NULL,                          
  refkey16    tinyint                NOT NULL,                          
  frgndbname  varchar(50)            NULL,                              
  pmrydbname  varchar(50)            NULL                               
 )                                                                      
   INSERT INTO  #t_sysreferences 
       SELECT constrid, tableid, reftabid, keycnt, status, frgndbid, pmrydbid,
              fokey1, fokey2, fokey3, fokey4, fokey5, fokey6,
              fokey7, fokey8, fokey9, fokey10, fokey11, fokey12,
              fokey13, fokey14, fokey15, fokey16,
              refkey1, refkey2, refkey3, refkey4, refkey5, refkey6,
              refkey7, refkey8, refkey9, refkey10, refkey11, refkey12,
              refkey13, refkey14, refkey15, refkey16,
              frgndbname, pmrydbname
       FROM   sysreferences
       WHERE  tableid  = object_id(@objname)
          OR  reftabid = object_id(@objname)
SET ROWCOUNT 1
WHILE 1 = 1
BEGIN
/*
** Now we obtain the referential dependency information
*/
     SELECT  @constrid = constrid, @tableid = tableid, @reftabid = reftabid, 
             @keycnt = keycnt, @status = status, @frgndbid = frgndbid, 
             @pmrydbid = pmrydbid, @fokey1 = fokey1, @fokey2 = fokey2, 
             @fokey3 = fokey3, @fokey4 = fokey4, @fokey5 = fokey5,
             @fokey6 = fokey6, @fokey7 = fokey7, @fokey8 = fokey8,
             @fokey9 = fokey9, @fokey10 = fokey10, @fokey11 = fokey11,
             @fokey12 = fokey12, @fokey13 = fokey13, @fokey14 = fokey14,
             @fokey13 = fokey13, @fokey14 = fokey14, @fokey15 = fokey15,
             @fokey16 = fokey16, 
             @refkey1 = refkey1, @refkey2 = refkey2, @refkey3 = refkey3,
             @refkey4 = refkey4, @refkey5 = refkey5, @refkey6 = refkey6,
             @refkey7 = refkey7, @refkey8 = refkey8, @refkey9 = refkey9,
             @refkey10 = refkey10, @refkey11 = refkey11, @refkey12 = refkey12,
             @refkey13 = refkey13, @refkey14 = refkey14, @refkey15 = refkey15,
             @refkey16 = refkey16,
             @frgndbname = frgndbname, @pmrydbname = pmrydbname
      FROM   #t_sysreferences
      WHERE  tableid  = object_id(@objname)
         OR  reftabid = object_id(@objname)
      IF @@rowcount = 0 break
      /*** Set the Database id's from the Database names */
      SELECT @pmrydbid = db_id()
      SELECT @frgndbid = db_id()
      IF @frgndbname != NULL
    SELECT @frgndbid = db_id(@frgndbname)
      IF @pmrydbname != NULL
    SELECT @pmrydbid = db_id(@pmrydbname)
      /*
      **   Check if either primary or dependent dbids are from this database.
      **   If both are not, that means we have an invalid entry here.
      **   Otherwise prefix the database name to the tablename.
      */
      SELECT  @pmrytab = object_name(@reftabid, @pmrydbid)
      SELECT    @frgntab = object_name(@tableid,  @frgndbid)
      /*
      ** Need to enhance this ...
      */
      IF @frgndbid != db_id()
      BEGIN
    SELECT @frgntab = db_name(@frgndbid) + '..' + @frgntab
      END
      ELSE
      BEGIN
    IF @pmrydbid != db_id()
           SELECT @pmrytab = db_name(@pmrydbid) + '..' + @pmrytab
      END

      SELECT @foreign_keys = convert(char(255),
      isnull(col_name(@tableid, @fokey1 , @frgndbid), '*') + ', '
    + isnull(col_name(@tableid, @fokey2 , @frgndbid), '*') + ', '
    + isnull(col_name(@tableid, @fokey3 , @frgndbid), '*') + ', '
    + isnull(col_name(@tableid, @fokey4 , @frgndbid), '*') + ', '
    + isnull(col_name(@tableid, @fokey5 , @frgndbid), '*') + ', '
    + isnull(col_name(@tableid, @fokey6 , @frgndbid), '*') + ', '
    + isnull(col_name(@tableid, @fokey7 , @frgndbid), '*') + ', '
    + isnull(col_name(@tableid, @fokey8 , @frgndbid), '*') + ', '
    + isnull(col_name(@tableid, @fokey9 , @frgndbid), '*') + ', '
    + isnull(col_name(@tableid, @fokey10, @frgndbid), '*') + ', '
    + isnull(col_name(@tableid, @fokey11, @frgndbid), '*') + ', '
    + isnull(col_name(@tableid, @fokey12, @frgndbid), '*') + ', '
    + isnull(col_name(@tableid, @fokey13, @frgndbid), '*') + ', '
    + isnull(col_name(@tableid, @fokey14, @frgndbid), '*') + ', '
    + isnull(col_name(@tableid, @fokey15, @frgndbid), '*') + ', '
    + isnull(col_name(@tableid, @fokey16 , @frgndbid), '*'))

      SELECT  @refrncd_keys = convert(char(255),
      isnull(col_name(@reftabid, @refkey1 , @pmrydbid), '*') + ', '
    + isnull(col_name(@reftabid, @refkey2 , @pmrydbid), '*') + ', '
    + isnull(col_name(@reftabid, @refkey3 , @pmrydbid), '*') + ' , '
    + isnull(col_name(@reftabid, @refkey4 , @pmrydbid), '*') + ', '
    + isnull(col_name(@reftabid, @refkey5 , @pmrydbid), '*') + ', '
    + isnull(col_name(@reftabid, @refkey6 , @pmrydbid), '*') + ', '
    + isnull(col_name(@reftabid, @refkey7 , @pmrydbid), '*' ) + ', '
    + isnull(col_name(@reftabid, @refkey8 , @pmrydbid), '*') + ', '
    + isnull(col_name(@reftabid, @refkey9 , @pmrydbid), '*') + ', '
    + isnull(col_name(@reftabid, @refkey10, @pmrydbid), '*') + ', '
    + isnull(col_name(@reftabid, @refkey11, @pmrydbid) , '*') + ', '
    + isnull(col_name(@reftabid, @refkey12, @pmrydbid), '*') + ', '
    + isnull(col_name(@reftabid, @refkey13, @pmrydbid), '*') + ', '
    + isnull(col_name(@reftabid, @refkey14, @pmrydbid), '*') + ', '
    + isnull(col_name(@reftabid, @refkey15, @pmrydbid), '*') + ', '
    + isnull(col_name(@reftabid, @refkey16, @pmrydbid), '*'))

     /* trim the list of key-columns */
     SELECT @foreign_keys =
               substring(@foreign_keys, 1, patindex('%, *%', @foreign_keys) - 1)
     SELECT @refrncd_keys =
        substring(@refrncd_keys, 1, patindex('%, *%', @refrncd_keys) - 1)

     SELECT @cnstrname = object_name(@constrid, @frgndbid)

     IF db_id() = @frgndbid
     BEGIN
       INSERT INTO #spconstrtab
          SELECT  @constrid, @cnstrname, @keycnt, c.error,
                    'referential constraint',
          'standard system error message number : 547',
          'ALTER TABLE '+ @frgntab + ' ADD CONSTRAINT ' + @cnstrname +
                  ' FOREIGN KEY (' + @foreign_keys +
          ') REFERENCES ' + @pmrytab + '(' + @refrncd_keys + ')'
      FROM sysconstraints c
      WHERE c.constrid = @constrid
     END
     ELSE
     BEGIN
       INSERT INTO #spconstrtab
      SELECT  @constrid, @cnstrname, @keycnt, 0,
              'referential constraint',
          'standard system error message number : 547',
          'ALTER TABLE '+ @frgntab + ' ADD CONSTRAINT ' + @cnstrname +
          ' FOREIGN KEY (' + @foreign_keys +
          ') REFERENCES ' + @pmrytab + '(' + @refrncd_keys + ')'
     END
     DELETE FROM #t_sysreferences
      WHERE  tableid  = object_id(@objname)
         OR  reftabid = object_id(@objname)
END
DROP TABLE #t_sysreferences

SET ROWCOUNT 0

/*
**    Now we setup the error message, if user defined.
*/
UPDATE #spconstrtab
SET constraint_msg = description 
FROM sysusermessages u, #spconstrtab c
WHERE c.constraint_ermsg > 20000
AND u.error = c.constraint_ermsg

/*
**    Now prettyprint the results
*/
IF @propt NOT LIKE 'detail%'
BEGIN
  DECLARE @len1 int, @len2 int, @len3 int

  SELECT @len1 = max(datalength(constraint_name)) FROM #spconstrtab
  SELECT @len2 = max(datalength(constraint_desc)) FROM #spconstrtab

  IF (@len1 < 15 AND @len2 < 60)
    BEGIN
      SELECT  convert(char(75), constraint_desc)
    FROM #spconstrtab
    ORDER BY constraint_type
    END
    ELSE 
    IF (@len2 < 60)
       BEGIN
          SELECT convert(char(60), constraint_desc)
          FROM #spconstrtab
        ORDER BY constraint_type
       END
    ELSE
    BEGIN
      SELECT constraint_desc
      FROM #spconstrtab
      ORDER BY constraint_type
      /*
    SELECT  name = constraint_name,
        defn = constraint_desc
        FROM #spconstrtab
        ORDER BY constraint_type  */
    END
END
/* Show all details -  pretty printing is not required for this perhaps ? */
ELSE
BEGIN
  SELECT @len1 = max(datalength(constraint_name)) FROM #spconstrtab
  SELECT @len2 = max(datalength(constraint_msg )) FROM #spconstrtab
  SELECT @len3 = max(datalength(constraint_desc)) FROM #spconstrtab

  IF (@len1 < 15 AND @len3 < 60)
  BEGIN
    SELECT convert(char(75), constraint_desc), constraint_msg
    FROM #spconstrtab
    ORDER BY constraint_type
    /*
    SELECT    name = convert(char(15), constraint_name),
        defn = convert(char(60), constraint_desc),
        msg  = constraint_msg
        FROM #spconstrtab
        ORDER BY constraint_type
     */
  END
  ELSE
  BEGIN
    SELECT    name =  constraint_name,
        type = constraint_type,
        defn = constraint_desc,
        msg  = constraint_msg
    FROM #spconstrtab
    ORDER BY constraint_type
  END
END 
   DROP TABLE #spconstrtab
END

BEGIN

SELECT owner      = user_name(o.uid),
       name       = o.name,
       index_name = i.name,
       indexid    = i.indid,
       status     = i.status,
       createstmt = convert(varchar(127),'N.A.'),
       keylist    = convert(varchar(127),'N.A.'),
       endingstmt = convert(varchar(127),') '),
       segment       = s.name
INTO   #indexlist
FROM   sysobjects o, sysindexes i, syssegments s
WHERE  i.id   = o.id
AND    o.type in ('U', 'S')
AND    isnull(@objname,o.name)=o.name
AND    i.indid > 0 and i.indid <> 255
AND i.segment=s.segment

IF @@rowcount = 0
BEGIN
  IF @objname IS NULL
  BEGIN
    print 'No Indexes found for %1!', @objname
  END
END
else
begin
/* delete multiple rows */
DELETE #indexlist
FROM   #indexlist a, #indexlist b
WHERE  a.indexid = 0
AND    b.indexid != 0
AND    a.name = b.name

UPDATE #indexlist
SET    createstmt='create'

UPDATE #indexlist
SET    createstmt = rtrim(createstmt)+' unique'
WHERE  status & 2 = 2

UPDATE #indexlist
SET    createstmt = rtrim(createstmt)+' clustered'
WHERE  indexid = 1

UPDATE #indexlist
SET    createstmt = rtrim(createstmt)+' nonclustered'
WHERE  indexid != 1

UPDATE #indexlist
SET    createstmt = rtrim(createstmt)+' index '+rtrim(index_name)+' on '+
            rtrim(owner)+'.'+rtrim(name)+' ('

DECLARE @count int
SELECT  @count=1

WHILE ( @count < 17 )    /* 16 appears to be the max number of indexes */
BEGIN
  IF @count=1
     UPDATE #indexlist
     SET    keylist=index_col(name,indexid,@count)
     WHERE  index_col(name,indexid,@count) is not null
  ELSE
     UPDATE #indexlist
    SET    keylist=rtrim(keylist)+','+index_col(name,indexid,@count)
    WHERE  index_col(name,indexid,@count) is not null

  IF @@rowcount=0    break

  SELECT @count=@count+1
END

UPDATE #indexlist
SET endingstmt=rtrim(endingstmt)+' with ignore_dup_key'
WHERE status&1 = 1

UPDATE #indexlist
SET endingstmt=rtrim(endingstmt)+' with ignore_dup_row'
WHERE status&4 = 4

UPDATE #indexlist
SET endingstmt=rtrim(endingstmt)+' with allow_dup_row'
WHERE status&64 = 64

UPDATE #indexlist
SET segment='''default'''
WHERE segment = 'default'

UPDATE #indexlist
SET endingstmt=rtrim(endingstmt)+' on '+segment

SELECT 'Text' = convert(varchar(255),createstmt+keylist+endingstmt)
FROM #indexlist
ORDER BY owner,name,indexid

end

SELECT name       = o.name,
       index_name = i.name,
       createstmt = convert(varchar(127),'N.A.'),
       segment       = s.name
INTO   #indexlist2
FROM   sysobjects o, sysindexes i, syssegments s
WHERE  i.id   = o.id
AND    o.type in ('U', 'S')
AND    isnull(@objname,o.name)=o.name
AND    i.indid = 255
AND i.segment=s.segment

IF @@rowcount = 0
BEGIN
  IF @objname IS NULL
  BEGIN
    print 'No Text-Index found for %1!', @objname
  END
END
else
begin
	UPDATE #indexlist2
	SET    createstmt = 'sp_placeobject '+segment+', '''+name+'.'+index_name+''''
	SELECT 'Text' = convert(varchar(255),createstmt)
	FROM #indexlist2
end
END

/* any rules or defaults which aren't implicit due to the datatype? */

create table #msgs(id numeric identity, msg varchar(255))
insert    #msgs
select    'execute sp_bindrule '+rtrim(object_name(c.domain))+', '''+rtrim(object_name(c.id))+'.'+rtrim(c.name)+''''
from    systypes t, 
        syscolumns c
where    t.usertype = c.usertype
and        c.id = @objid
and        (t.domain != c.domain)
and        c.domain not in
        (select    constrid
        from    sysconstraints)

insert    #msgs
select    'execute sp_bindefault '+rtrim(object_name(c.cdefault))+', '''+rtrim(object_name(c.id))+'.'+rtrim(c.name)+''''
from    systypes t, 
        syscolumns c
where    t.usertype = c.usertype
and        c.id = @objid
and        (tdefault != cdefault)
and        exists
        (select    *
        from    sysprocedures p
        where    p.id = c.cdefault
        and        p.status & 4096 != 4096)

select    @objid = min(id)
from    #msgs

while (@objid is not NULL)
begin
    select    msg 
    from    #msgs
    where    id = @objid

    select    @objid = min(id)
    from    #msgs
    where    id > @objid
end

drop table #msgs

declare	@rows	int,
		@key1	varchar(255),
		@key2	varchar(255),
		@key3	varchar(255)

select	@rows = 0

SELECT  @objid=object_id(@objname)

create table #keys(key1 varchar(255), key2 varchar(255) NULL, key3 varchar(255) NULL)

insert	#keys
select	key1 = 'execute sp_primarykey '+rtrim(object_name(k.id))
		+rtrim(substring(', '+col_name(k.id, key1),sign(keycnt),30))
		+rtrim(substring(', '+col_name(k.id, key2),sign(keycnt-1),30))
		+rtrim(substring(', '+col_name(k.id, key3),sign(keycnt-2),30))
		+rtrim(substring(', '+col_name(k.id, key4),sign(keycnt-3),30))
		+rtrim(substring(', '+col_name(k.id, key5),sign(keycnt-4),30))
		+rtrim(substring(', '+col_name(k.id, key6),sign(keycnt-5),30)),
		key2 = rtrim(substring(', '+col_name(k.id, key7),sign(keycnt-6),30))
		+rtrim(substring(', '+col_name(k.id, key8),sign(keycnt-7),30)),
		key3 = NULL
from	syskeys k
where	k.type = 1
and		k.id = @objid

select	@rows = @rows + @@ROWCOUNT

insert	#keys
select	key1 = 'execute sp_foreignkey '+rtrim(object_name(k.id))+', '+rtrim(object_name(depid))
		+rtrim(substring(', '+col_name(k.id, key1),sign(keycnt),30))
		+rtrim(substring(', '+col_name(k.id, key2),sign(keycnt-1),30))
		+rtrim(substring(', '+col_name(k.id, key3),sign(keycnt-2),30))
		+rtrim(substring(', '+col_name(k.id, key4),sign(keycnt-3),30))
		+rtrim(substring(', '+col_name(k.id, key5),sign(keycnt-4),30)),
		key2 = rtrim(substring(', '+col_name(k.id, key6),sign(keycnt-5),30))
		+rtrim(substring(', '+col_name(k.id, key7),sign(keycnt-6),30))
		+rtrim(substring(', '+col_name(k.id, key8),sign(keycnt-7),30)),
		key3 = NULL
from	syskeys k
where	k.type = 2
and		k.id = @objid

select	@rows = @rows + @@ROWCOUNT

insert	#keys
select	'execute sp_commonkey '+rtrim(object_name(k.id))+', '+rtrim(object_name(depid))
		+rtrim(substring(', '+col_name(k.id, key1),sign(keycnt),30))
		+rtrim(substring(', '+col_name(depid, depkey1),sign(keycnt),30))
		+rtrim(substring(', '+col_name(k.id, key2),sign(keycnt-1),30))
		+rtrim(substring(', '+col_name(depid, depkey2),sign(keycnt-1),30))
		+rtrim(substring(', '+col_name(k.id, key3),sign(keycnt-2),30)),
		key2 = rtrim(substring(', '+col_name(depid, depkey3),sign(keycnt-2),30))
		+rtrim(substring(', '+col_name(k.id, key4),sign(keycnt-3),30))
		+rtrim(substring(', '+col_name(depid, depkey4),sign(keycnt-3),30))
		+rtrim(substring(', '+col_name(k.id, key5),sign(keycnt-4),30))
		+rtrim(substring(', '+col_name(depid, depkey5),sign(keycnt-4),30))
		+rtrim(substring(', '+col_name(k.id, key6),sign(keycnt-5),30))
		+rtrim(substring(', '+col_name(depid, depkey6),sign(keycnt-5),30)),
		key3 = rtrim(substring(', '+col_name(k.id, key7),sign(keycnt-6),30))
		+rtrim(substring(', '+col_name(depid, depkey7),sign(keycnt-6),30))
		+rtrim(substring(', '+col_name(k.id, key8),sign(keycnt-7),30))
		+rtrim(substring(', '+col_name(depid, depkey8),sign(keycnt-7),30))
from	syskeys k
where	k.type = 3
and		k.id = @objid

select	@rows = @rows + @@ROWCOUNT

if @rows = 0
begin
	print 'no keys found for %1!', @objname
end
else
begin
declare keyc cursor for
select	key1, key2, key3
from	#keys

open keyc

fetch keyc into @key1, @key2, @key3

while (@@sqlstatus = 0)
begin
	select @key1+@key2+@key3

	fetch keyc into @key1, @key2, @key3
end

close keyc
deallocate cursor keyc

drop table #keys
  
end

declare @user	varchar(30),
		@uid	int,
		@cmd	varchar(30),
		@columns varbinary(32),
		@action	varchar(30)

if not exists(select * from sysprotects where id = @objid)
begin
	print '/* no specific permissions found for %1! */', @objid
end
else
begin
declare protects cursor for
select	p.uid,
		action = lower(va.name), 
		cmd = lower(vp.name),
		columns
from	sysprotects p,
		master..spt_values va,
		master..spt_values vp
where	p.id = @objid
and		va.type = 'T'
and		va.number = action
and		vp.type = 'T'
and		vp.number = protecttype + 204
order by p.uid

open protects

fetch	protects
into	@uid,
		@action,
		@cmd,
		@columns

while (@@sqlstatus = 0)
begin
	select	@msg = rtrim(@cmd) + ' ' + rtrim(@action) + ' on '+rtrim(@objname)

	if @columns is NOT NULL and @columns != 0x01
	begin
		select	@msg	= @msg+'('

		select	@msg = @msg + col_name(@objid, number) + ', '
		from	master..spt_values
		where	type = 'P'
		and		convert(tinyint, substring(@columns, low, 1)) & high != 0

		select @msg = substring(@msg,1,datalength(@msg)-2)+')'

	end

	if @cmd = 'grant'
		select	@msg = @msg + ' to '
	else
		select	@msg = @msg + ' from '
		
	select	@msg + user_name(@uid)

	fetch	protects
	into	@uid,
			@action,
			@cmd,
			@columns
end

close protects
deallocate cursor protects
end

RETURN (0)
END
go     
