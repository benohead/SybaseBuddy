package com.benohead.tools.sybase;

import javax.swing.text.AttributeSet;
import javax.swing.text.BadLocationException;
import javax.swing.text.PlainDocument;

@SuppressWarnings("serial")
public class NumericDocument extends PlainDocument {
	// How long can it be? (you could pass this to the
	// constructor for text fields of different lengths)
	private static final int MAX_LENGTH = 5;

	public void insertString(int offs, String str, AttributeSet a) throws BadLocationException {
		if (str == null) {
			return;
		}
		// How many spaces are free?
		int available = MAX_LENGTH - getLength();

		// If full already, quit
		if (available <= 0) {
			return;
		}
		char[] digits = new char[str.length()];
		int count = 0;
		// Copy only digits to buffer; stop when we have enough
		// or when we reach the end of string
		for (; count < str.length() && count < available; count++) {
			char ch = str.charAt(count);
			if (Character.isDigit(ch)) {
				digits[count] = ch;
			}
		}
		// Insert the number of digits copied
		super.insertString(offs, new String(digits, 0, count), a);
	}
}
