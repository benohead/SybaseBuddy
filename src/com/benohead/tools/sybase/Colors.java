/**
 * 
 */
package com.benohead.tools.sybase;

import java.awt.Color;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * @author benohead
 * 
 */
@SuppressWarnings("serial")
public class Colors extends Color {
	public Colors(int arg0) {
		super(arg0);
	}

	public static final Color darkGreen = green.darker();
	public static final Color darkBlue = blue.darker();

	public static Color parseRgb(String input) {
		Pattern c = Pattern.compile("rgb *\\( *([0-9]+) *, *([0-9]+) *, *([0-9]+) *\\) *");
		Matcher m = c.matcher(input);

		if (m.matches()) {
			return new Color(Integer.valueOf(m.group(1)), // r
					Integer.valueOf(m.group(2)), // g
					Integer.valueOf(m.group(3))); // b
		}

		return null;
	}

	public static Color parseHsb(String input) {
		Pattern c = Pattern.compile("hsb *\\( *([0-9]+) *, *([0-9]+) *, *([0-9]+) *\\) *");
		Matcher m = c.matcher(input);

		if (m.matches()) {
			Color.getHSBColor(Integer.valueOf(m.group(1)), // h
					Integer.valueOf(m.group(2)), // s
					Integer.valueOf(m.group(3))); // b
		}

		return null;
	}
}
