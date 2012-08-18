package com.benohead.tools.sybase;

import java.util.HashMap;

import javax.swing.table.DefaultTableModel;

final class SqlTableModel extends DefaultTableModel {
    /**
	 * 
	 */
    private static final long serialVersionUID = 1L;
    @SuppressWarnings("rawtypes")
    private final HashMap<Integer, Class> columnClasses = new HashMap<Integer, Class>();

    @Override
    public Class<?> getColumnClass(int columnIndex) {
        if (columnClasses.containsKey(columnIndex)) {
            return columnClasses.get(columnIndex);
        }
        return super.getColumnClass(columnIndex);
    }

    public void setColumnClass(int i, @SuppressWarnings("rawtypes") Class class1) {
        columnClasses.remove(i);
        columnClasses.put(i, class1);
    }

    @SuppressWarnings("unchecked")
    public void setColumnName(int nColumnIndex, String strColumnName) {
        columnIdentifiers.set(nColumnIndex, strColumnName);

        fireTableStructureChanged();
    }
}