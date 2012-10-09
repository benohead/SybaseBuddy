package com.benohead.tools.sybase;

import java.awt.Component;
import java.awt.Dialog;
import java.awt.Window;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.event.HierarchyEvent;
import java.awt.event.HierarchyListener;
import java.lang.reflect.InvocationTargetException;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.sql.SQLWarning;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.Hashtable;

import javax.swing.JFrame;
import javax.swing.JMenuItem;
import javax.swing.JOptionPane;
import javax.swing.JPopupMenu;
import javax.swing.JScrollPane;
import javax.swing.JTextArea;
import javax.swing.SwingUtilities;

import com.sybase.jdbc3.jdbc.SybSQLWarning;

@SuppressWarnings("serial")
class SqlTablePopUpMenu extends JPopupMenu {
    JMenuItem anItem;

    public SqlTablePopUpMenu(final JFrame frame, SqlTable sqlTable, int column, int row, Hashtable<String, ArrayList<ContextMenuItem>> contextMenuItems) {
        String columnName = sqlTable.getColumnName(column);
        final Object valueAt = sqlTable.getValueAt(row, column);
        final String value = valueAt != null ? valueAt.toString() : null;

        if (value != null) {
            String normalizedColumnName = normalizeColumnName(columnName);
            ArrayList<ContextMenuItem> menu = contextMenuItems.get(normalizedColumnName);
            if (menu != null) {
	            for (ContextMenuItem contextMenuItem2 : menu) {
	                ContextMenuItem contextMenuItem = contextMenuItem2;
	                final String menuItemText = contextMenuItem.menuItem.replaceAll("%value%", value);
	                anItem = new JMenuItem(menuItemText);
	                final String sql = contextMenuItem.sql.replaceAll("%value%", value);
	                if (contextMenuItem.action.equalsIgnoreCase("execute")) {
	                    anItem.addActionListener(new ActionListener() {
	                        public void actionPerformed(ActionEvent arg0) {
	                            try {
	                                SybaseBuddyApplication.connection.createStatement().execute(sql);
	                            }
	                            catch (SQLException e) {
	                                // TODO Auto-generated catch block
	                                e.printStackTrace();
	                            }
	                        }
	                    });
	                }
	                else if (contextMenuItem.action.equalsIgnoreCase("askandexecute")) {
	                    anItem.addActionListener(new ActionListener() {
	                        public void actionPerformed(ActionEvent arg0) {
	                            try {
	                                int result = JOptionPane.showConfirmDialog(frame, "Are you sure you want to " + menuItemText + " ?", menuItemText, JOptionPane.YES_NO_OPTION);
	                                if (result == JOptionPane.YES_OPTION) {
	                                    SybaseBuddyApplication.connection.createStatement().execute(sql);
	                                }
	                            }
	                            catch (SQLException e) {
	                                // TODO Auto-generated catch block
	                                e.printStackTrace();
	                            }
	                        }
	                    });
	                }
	                else if (contextMenuItem.action.equalsIgnoreCase("displaytable")) {
	                    anItem.addActionListener(new ActionListener() {
	                        public void actionPerformed(ActionEvent arg0) {
	                            displaySqlTableDialog(frame, sql);
	                        }
	                    });
	                }
	                else if (contextMenuItem.action.equalsIgnoreCase("displayresultsets")) {
	                    anItem.addActionListener(new ActionListener() {
	                        public void actionPerformed(ActionEvent arg0) {
	                            try {
	                                displayResultSetsInDialog(frame, sql);
	                            }
	                            catch (SQLException e) {
	                                // TODO Auto-generated catch block
	                                e.printStackTrace();
	                            }
	                        }
	                    });
	                }
	                else if (contextMenuItem.action.equalsIgnoreCase("displaywarnings")) {
	                    anItem.addActionListener(new ActionListener() {
	                        public void actionPerformed(ActionEvent arg0) {
	                            try {
	                                displayWarningsInDialog(frame, sql);
	                            }
	                            catch (SQLException e) {
	                                // TODO Auto-generated catch block
	                                e.printStackTrace();
	                            }
	                        }
	                    });
	                }
	                add(anItem);
	            }
            }
        }
    }

    private void displayResultSetsInDialog(final JFrame frame, String sql) throws SQLException {
        StringBuilder warnings = new StringBuilder();
        StringBuilder text = new StringBuilder();
        Statement statement = SybaseBuddyApplication.connection.createStatement();
        boolean results = statement.execute(sql);
        int rowsAffected = 0;
        do {
            if (results) {
                ResultSet resultSet = statement.getResultSet();
                ResultSetMetaData metaData = resultSet.getMetaData();
                int numColumns = metaData.getColumnCount();
                while (resultSet.next()) {
                    StringBuilder row = new StringBuilder();
                    for (int i = 1; i <= numColumns; i++) {
                        if (i > 1) {
                            row.append("\t");
                        }
                        row.append(resultSet.getString(i));
                    }
                    text.append(row.toString()).append("\n");
                }
            }
            else {
                rowsAffected = statement.getUpdateCount();
            }
            SQLWarning sqw = statement.getWarnings();
            while ((sqw != null) && (sqw instanceof SybSQLWarning)) {
                warnings.append(sqw.getMessage());
                sqw = sqw.getNextWarning();
            }
            statement.clearWarnings();
            results = statement.getMoreResults();
        }
        while (results || (rowsAffected != -1));
        System.out.println(warnings);
        displayTextAreaDialog(frame, text.toString());
    }

    private void displaySqlTableDialog(final JFrame frame, String sql) {
        // create an SQL table
    	TabDefinition tabDef = new TabDefinition();
    	tabDef.setSql(sql);
        SqlTable table = new SqlTable(tabDef);
        try {
            table.refresh(true);
        }
        catch (InterruptedException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
        }
        catch (InvocationTargetException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
        }
        // wrap a scrollpane around it
        showDialog(frame, table);
    }

    private void displayTextAreaDialog(final JFrame frame, String string) {
        // create a JTextArea
        JTextArea textArea = new JTextArea(20, 80);
        textArea.setText(string);
        textArea.setEditable(false);
        showDialog(frame, textArea);
    }

    private void displayWarningsInDialog(final JFrame frame, String sql) throws SQLException {
        Statement statement = SybaseBuddyApplication.connection.createStatement();
        statement.execute(sql);
        StringBuilder warnings = getWarnings(statement);
        displayTextAreaDialog(frame, warnings.toString());
    }

    private StringBuilder getWarnings(Statement statement) throws SQLException {
        boolean results;
        StringBuilder warnings = new StringBuilder();
        int rowsAffected = 0;
        do {
            rowsAffected = statement.getUpdateCount();
            SQLWarning sqw = statement.getWarnings();
            while ((sqw != null) && (sqw instanceof SybSQLWarning)) {
                warnings.append(sqw.getMessage());
                sqw = sqw.getNextWarning();
            }
            statement.clearWarnings();
            results = statement.getMoreResults();
        }
        while (results || (rowsAffected != -1));
        return warnings;
    }

    private String normalizeColumnName(String columnName) {
        return columnName.replace(" ", "").replace("_", "").replace("-", "").toLowerCase();
    }

    private void showDialog(Component frame, final Component component) {
        // wrap a scrollpane around the component
        JScrollPane scrollPane = new JScrollPane(component);
        // make the dialog resizable
        component.addHierarchyListener(new HierarchyListener() {
            public void hierarchyChanged(HierarchyEvent e) {
                Window window = SwingUtilities.getWindowAncestor(component);
                if (window instanceof Dialog) {
                    Dialog dialog = (Dialog) window;
                    if (!dialog.isResizable()) {
                        dialog.setResizable(true);
                    }
                }
            }
        });
        // display them in a message dialog
        JOptionPane.showMessageDialog(frame, scrollPane);
    }
}