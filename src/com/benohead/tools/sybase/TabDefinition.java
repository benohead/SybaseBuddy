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
	private ArrayList<IconDefinition> icons = new ArrayList<IconDefinition>();

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

	public ArrayList<IconDefinition> getIcons() {
		return icons;
	}

	public void setIcons(ArrayList<IconDefinition> icons) {
		this.icons = icons;
	}

	public void addIcon(IconDefinition iconDefinition) {
		this.icons.add(iconDefinition);
	}
}
