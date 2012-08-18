package com.benohead.tools.sybase;

public class ServerEntry {

	private static final String DEFAULT_PORT = "2055";
	private String name;
	private String value;

	public String getValue() {
		return value;
	}

	public ServerEntry(String key, String value) {
		this.name = key;
		this.value = value;
	}

	public String getServerName() {
		return name;
	}

	public void setServerName(String name) {
		this.name = name;
	}

	public String getServerAddress() {
		return value.split(":")[0];
	}

	public void setServerAddress(String address) {
		String[] split = value.split(":");
		StringBuilder builder = new StringBuilder(address);
		for (int i = 1; i < split.length; i++) {
			builder.append(':').append(split[i]);
		}
		value = builder.toString();
	}

	public String getServerPort() {
		String[] split = value.split(":");
		if (split.length > 1) {
			return split[1];
		}
		return DEFAULT_PORT;
	}

	public void setServerPort(String port) {
		String[] split = value.split(":");
		String address = "";
		if (split.length > 0) {
			address = split[0];
		}
		StringBuilder builder = new StringBuilder(address);
		builder.append(':').append(port);
		for (int i = 2; i < split.length; i++) {
			builder.append(':').append(split[i]);
		}
		value = builder.toString();
	}

	@Override
	public String toString() {
		return name;
	}
}
