/**
 * 
 */
package com.benohead.tools.sybase;

import java.awt.Color;
import java.awt.Component;
import java.awt.EventQueue;
import java.awt.Point;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.lang.reflect.InvocationTargetException;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.Hashtable;
import java.util.Vector;

import javax.script.ScriptEngine;
import javax.script.ScriptEngineManager;
import javax.script.ScriptException;
import javax.swing.JFrame;

import org.jdesktop.swingx.JXTable;
import org.jdesktop.swingx.decorator.ColorHighlighter;
import org.jdesktop.swingx.decorator.ComponentAdapter;
import org.jdesktop.swingx.decorator.HighlightPredicate;
import org.jdesktop.swingx.decorator.HighlighterFactory;

/**
 * @author benohead
 * 
 */
public class SqlTable extends JXTable {

	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;
	private String sql;
	private SqlTableModel tableModel = new SqlTableModel();

	public SqlTable(String sql) {
		this.sql = sql;
		this.setHorizontalScrollEnabled(true);
		this.setModel(tableModel);
		this.setEditable(false);
		this.setColumnControlVisible(true);
		this.addHighlighter(HighlighterFactory.createAlternateStriping());
		this.addHighlighter(new ColorHighlighter(HighlightPredicate.ROLLOVER_ROW, Color.LIGHT_GRAY, null));
		HighlightPredicate predicate = new HighlightPredicate() {

			@Override
			public boolean isHighlighted(Component renderer, ComponentAdapter adapter) {
				int columnCount = adapter.getColumnCount();
				for (int columnIndex = 0; columnIndex < columnCount; columnIndex++) {
					if (!adapter.getColumnName(columnIndex).equals("blocked")) {
						continue;
					}
					String value = adapter.getFilteredStringAt(adapter.row, columnIndex);
				    ScriptEngineManager mgr = new ScriptEngineManager();
				    ScriptEngine jsEngine = mgr.getEngineByName("JavaScript");
				 
				    jsEngine.put("value", value);
				    Object highlight = null;
					try
				    {
						String rule = "value != \"0\"";
						highlight = jsEngine.eval("new java.lang.Boolean("+rule+");");
				    }
				    catch (ScriptException ex)
				    {
				        ex.printStackTrace();
				    }
					if (highlight != null && highlight.equals(Boolean.TRUE)) {
						return true;
					}
				}
				return false;
			}
		};
		this.addHighlighter(new ColorHighlighter(predicate, null, Color.RED));
	}

	public void refresh(boolean now) throws InterruptedException, InvocationTargetException {
		Runnable runnable = new Runnable() {
			public void run() {
				try {
					int selectedRow = SqlTable.this.getSelectedRow();
					int selectedColumn = SqlTable.this.getSelectedColumn();
					Statement statement = SybaseBuddyApplication.connection.createStatement();
					ResultSet result = statement.executeQuery(sql);
					ResultSetMetaData metaData = result.getMetaData();
					int columnCount = metaData.getColumnCount();
					if (tableModel.getColumnCount() != columnCount) {
						tableModel.setColumnCount(columnCount);
					}
					tableModel.setRowCount(0);
					for (int i = 0; i < columnCount; i++) {
						String columnLabel = metaData.getColumnLabel(i + 1);
						if (!columnLabel.equals(tableModel.getColumnName(i))) {
							tableModel.setColumnName(i, columnLabel);
						}
						if (metaData.getColumnType(i + 1) == 4) {
							// int
							tableModel.setColumnClass(i, Integer.class);
						} else {
							tableModel.setColumnClass(i, tableModel.getColumnClass(i));
						}
					}
					while (result.next()) {
						Vector<Object> rowData = new Vector<Object>();
						for (int i = 0; i < columnCount; i++) {
							Object value = result.getObject(i + 1);
							rowData.add(value);
						}
						tableModel.addRow(rowData);
					}
					tableModel.fireTableDataChanged();
					SqlTable.this.changeSelection(selectedRow, selectedColumn, false, false);
				} catch (Exception e) {
					e.printStackTrace();
					SybaseBuddyApplication.handleException(e);
				}
			}
		};
		if (now) {
			runnable.run();
		} else {
			EventQueue.invokeLater(runnable);
		}
	}

	public void export(File file) throws IOException {
		FileWriter out = new FileWriter(file);
		for (int i = 0; i < tableModel.getColumnCount(); i++) {
			out.write(tableModel.getColumnName(i) + "\t");
		}
		out.write("\n");

		for (int i = 0; i < tableModel.getRowCount(); i++) {
			for (int j = 0; j < tableModel.getColumnCount(); j++) {
				Object value = tableModel.getValueAt(i, j);
				out.write(value != null ? value.toString() : "NULL" + "\t");
			}
			out.write("\n");
		}

		out.close();
	}

}

class SqlTableClickListener extends MouseAdapter {
	private JFrame frame;
	private Hashtable<String, ArrayList<ContextMenuItem>> contextMenuItems;

	public SqlTableClickListener(JFrame frame, Hashtable<String, ArrayList<ContextMenuItem>> contextMenuItems) {
		this.frame = frame;
		this.contextMenuItems = contextMenuItems;
	}

	public void mousePressed(MouseEvent e) {
		if (e.isPopupTrigger())
			doPop(e);
	}

	public void mouseReleased(MouseEvent e) {
		if (e.isPopupTrigger())
			doPop(e);
	}

	private void doPop(MouseEvent e) {
		if (!e.isPopupTrigger()) {
			return;
		}
		SqlTablePopUpMenu menu = new SqlTablePopUpMenu(frame, (SqlTable) e.getComponent(), ((SqlTable) e.getComponent()).columnAtPoint(new Point(e
				.getX(), e.getY())), ((SqlTable) e.getComponent()).rowAtPoint(new Point(e.getX(), e.getY())), contextMenuItems);
		menu.show(e.getComponent(), e.getX(), e.getY());
	}
}
