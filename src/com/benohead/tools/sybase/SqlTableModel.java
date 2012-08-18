package com.benohead.tools.sybase;

import java.util.HashMap;

import javax.swing.table.DefaultTableModel;

final class SqlTableModel extends DefaultTableModel {
	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;
	private HashMap<Integer, Class> columnClasses = new HashMap<Integer, Class>();

	public void setColumnName(int nColumnIndex, String strColumnName) {
		columnIdentifiers.set(nColumnIndex, strColumnName);

		fireTableStructureChanged();
	}

	public void setColumnClass(int i, Class class1) {
		columnClasses.remove(i);
		columnClasses.put(i, class1);
	}

	@Override
	public Class<?> getColumnClass(int columnIndex) {
		if (columnClasses.containsKey(columnIndex)) {
			return columnClasses.get(columnIndex);
		}
		return super.getColumnClass(columnIndex);
	}
}