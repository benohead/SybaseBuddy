/**
 * 
 */
package com.benohead.tools.sybase;

import java.util.ArrayList;

/**
 * @author benohead
 * 
 */
public class TabDefinition {
	private String sql;
	private ArrayList<ColorDefinition> colors = new ArrayList<ColorDefinition>();

	public ArrayList<ColorDefinition> getColors() {
		return colors;
	}

	public void setColors(ArrayList<ColorDefinition> colors) {
		this.colors = colors;
	}

	public void addColor(ColorDefinition color) {
		this.colors.add(color);
	}

	public void removeColors() {
		this.colors.clear();
	}

	public String getSql() {
		return sql;
	}

	public void setSql(String sql) {
		this.sql = sql;
	}
}
