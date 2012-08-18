package com.benohead.tools.sybase;

import java.awt.BorderLayout;
import java.awt.FlowLayout;
import java.awt.GridBagConstraints;
import java.awt.GridBagLayout;
import java.awt.Insets;
import java.awt.Toolkit;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.event.WindowAdapter;
import java.awt.event.WindowEvent;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.Enumeration;
import java.util.Hashtable;

import javax.swing.DefaultListModel;
import javax.swing.JButton;
import javax.swing.JDialog;
import javax.swing.JLabel;
import javax.swing.JList;
import javax.swing.JPanel;
import javax.swing.JTabbedPane;
import javax.swing.ListSelectionModel;
import javax.swing.SwingConstants;
import javax.swing.border.EmptyBorder;
import javax.swing.event.ListSelectionEvent;
import javax.swing.event.ListSelectionListener;

import org.jdesktop.swingx.JXTextField;

@SuppressWarnings("serial")
public class ConfigDialog extends JDialog {

	private final JPanel contentPanel = new JPanel();
	private JXTextField serverNameField;
	private JXTextField addressField;
	private JXTextField portField;
	private JLabel lblServerName;
	private JLabel lblIphost;
	private JLabel lblPort;
	private JLabel defaultPortLabel;
	private JList list;
	private DefaultListModel listModel = new DefaultListModel();
	protected ServerEntry selectedServer;;

	/**
	 * Launch the application.
	 */
	public static void main(String[] args) {
		try {
			ConfigDialog dialog = new ConfigDialog();
			dialog.setDefaultCloseOperation(JDialog.DISPOSE_ON_CLOSE);
			dialog.setVisible(true);
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	/**
	 * Create the dialog.
	 */
	public ConfigDialog() {
		addWindowListener(new WindowAdapter() {
			@Override
			public void windowOpened(WindowEvent event) {
				load();
			}
		});
		setTitle("Configuration");
		setIconImage(Toolkit.getDefaultToolkit().getImage(ConfigDialog.class.getResource("/icon.png")));
		setBounds(100, 100, 450, 300);
		getContentPane().setLayout(new BorderLayout());
		contentPanel.setBorder(new EmptyBorder(5, 5, 5, 5));
		getContentPane().add(contentPanel, BorderLayout.CENTER);
		contentPanel.setLayout(new BorderLayout(0, 0));
		{
			JTabbedPane tabbedPane = new JTabbedPane(JTabbedPane.TOP);
			contentPanel.add(tabbedPane);
			{
				JPanel serverPanel = new JPanel();
				tabbedPane.addTab("Servers", null, serverPanel, null);
				serverPanel.setLayout(new BorderLayout(0, 0));
				{
					JPanel panel_1 = new JPanel();
					serverPanel.add(panel_1, BorderLayout.WEST);
					panel_1.setLayout(new BorderLayout(0, 0));
					{
						list = new JList();
						list.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
						list.addListSelectionListener(new ListSelectionListener() {
							public void valueChanged(ListSelectionEvent listSelectionEvent) {
								boolean adjust = listSelectionEvent.getValueIsAdjusting();
								if (!adjust) {
									JList list = (JList) listSelectionEvent.getSource();
									selectedServer = (ServerEntry) list.getSelectedValue();
									if (selectedServer != null) {
										serverNameField.setText(selectedServer.getServerName());
										addressField.setText(selectedServer.getServerAddress());
										portField.setText(selectedServer.getServerPort());
									} else {
										serverNameField.setText("");
										addressField.setText("");
										portField.setText("");
									}
								}
							}
						});
						list.setModel(listModel);
						panel_1.add(list, BorderLayout.CENTER);
					}
					{
						JPanel panel = new JPanel();
						panel_1.add(panel, BorderLayout.SOUTH);
						{
							JButton button = new JButton("+");
							button.addActionListener(new ActionListener() {
								public void actionPerformed(ActionEvent arg0) {
									ServerEntry serverEntry = new ServerEntry("New_server", "");
									listModel.addElement(serverEntry);
								}
							});
							panel.add(button);
						}
						{
							JButton button = new JButton("-");
							button.addActionListener(new ActionListener() {
								public void actionPerformed(ActionEvent e) {
									selectedServer = (ServerEntry) list.getSelectedValue();
									int serverIndex = -1;
									for (int i = 0; i < listModel.size(); i++) {
										if (selectedServer.getServerName().equals(((ServerEntry) listModel.elementAt(i)).getServerName())) {
											serverIndex = i;
											break;
										}
									}
									listModel.remove(serverIndex);
								}
							});
							panel.add(button);
						}
					}
				}
				{
					JPanel panel = new JPanel();
					serverPanel.add(panel, BorderLayout.CENTER);
					GridBagLayout gbl_panel = new GridBagLayout();
					gbl_panel.columnWidths = new int[] { 111, 89, 73, 0 };
					gbl_panel.rowHeights = new int[] { 20, 20, 20, 0 };
					gbl_panel.columnWeights = new double[] { 0.0, 0.0, 0.0, Double.MIN_VALUE };
					gbl_panel.rowWeights = new double[] { 0.0, 0.0, 0.0, Double.MIN_VALUE };
					panel.setLayout(gbl_panel);
					{
						lblPort = new JLabel("Port:");
					}
					{
						lblServerName = new JLabel("Server name:");
					}
					GridBagConstraints gbc_lblServerName = new GridBagConstraints();
					gbc_lblServerName.anchor = GridBagConstraints.EAST;
					gbc_lblServerName.insets = new Insets(0, 5, 5, 5);
					gbc_lblServerName.gridx = 0;
					gbc_lblServerName.gridy = 0;
					panel.add(lblServerName, gbc_lblServerName);
					{
						serverNameField = new JXTextField();
						serverNameField.setPrompt("Enter the server name");
						serverNameField.setColumns(10);
					}
					GridBagConstraints gbc_serverNameField = new GridBagConstraints();
					gbc_serverNameField.fill = GridBagConstraints.HORIZONTAL;
					gbc_serverNameField.anchor = GridBagConstraints.LINE_START;
					gbc_serverNameField.insets = new Insets(0, 0, 5, 0);
					gbc_serverNameField.gridwidth = 2;
					gbc_serverNameField.gridx = 1;
					gbc_serverNameField.gridy = 0;
					panel.add(serverNameField, gbc_serverNameField);
					{
						lblIphost = new JLabel("IP Address/Hostname:");
					}
					GridBagConstraints gbc_lblIphost = new GridBagConstraints();
					gbc_lblIphost.anchor = GridBagConstraints.WEST;
					gbc_lblIphost.insets = new Insets(0, 5, 5, 5);
					gbc_lblIphost.gridx = 0;
					gbc_lblIphost.gridy = 1;
					panel.add(lblIphost, gbc_lblIphost);
					{
						addressField = new JXTextField();
						addressField.setPrompt("Enter the IP address/hostname");
						addressField.setColumns(10);
					}
					GridBagConstraints gbc_addressField = new GridBagConstraints();
					gbc_addressField.fill = GridBagConstraints.HORIZONTAL;
					gbc_addressField.anchor = GridBagConstraints.LINE_START;
					gbc_addressField.insets = new Insets(0, 0, 5, 0);
					gbc_addressField.gridwidth = 2;
					gbc_addressField.gridx = 1;
					gbc_addressField.gridy = 1;
					panel.add(addressField, gbc_addressField);
					GridBagConstraints gbc_lblPort = new GridBagConstraints();
					gbc_lblPort.anchor = GridBagConstraints.EAST;
					gbc_lblPort.insets = new Insets(0, 5, 0, 5);
					gbc_lblPort.gridx = 0;
					gbc_lblPort.gridy = 2;
					panel.add(lblPort, gbc_lblPort);
					{
						portField = new JXTextField();
						portField.setDocument(new NumericDocument());
						portField.setPrompt("portnumber");
						portField.setHorizontalAlignment(SwingConstants.CENTER);
						portField.setText("2055");
						portField.setColumns(5);
					}
					GridBagConstraints gbc_portField = new GridBagConstraints();
					gbc_portField.anchor = GridBagConstraints.LINE_START;
					gbc_portField.insets = new Insets(0, 0, 0, 5);
					gbc_portField.gridx = 1;
					gbc_portField.gridy = 2;
					panel.add(portField, gbc_portField);
					{
						defaultPortLabel = new JLabel("(default: 2055)");
					}
					GridBagConstraints gbc_defaultPortLabel = new GridBagConstraints();
					gbc_defaultPortLabel.fill = GridBagConstraints.HORIZONTAL;
					gbc_defaultPortLabel.anchor = GridBagConstraints.WEST;
					gbc_defaultPortLabel.gridx = 2;
					gbc_defaultPortLabel.gridy = 2;
					panel.add(defaultPortLabel, gbc_defaultPortLabel);
				}
			}
		}
		{
			JPanel buttonPane = new JPanel();
			buttonPane.setLayout(new FlowLayout(FlowLayout.RIGHT));
			getContentPane().add(buttonPane, BorderLayout.SOUTH);
			{
				JButton okButton = new JButton("OK");
				okButton.addActionListener(new ActionListener() {
					public void actionPerformed(ActionEvent arg0) {
						try {
							save();
							dispose();
						} catch (FileNotFoundException e) {
							SybaseBuddyApplication.handleException(e);
						} catch (IOException e) {
							SybaseBuddyApplication.handleException(e);
						}
					}
				});
				okButton.setActionCommand("OK");
				buttonPane.add(okButton);
				getRootPane().setDefaultButton(okButton);
			}
			{
				JButton cancelButton = new JButton("Cancel");
				cancelButton.addActionListener(new ActionListener() {
					public void actionPerformed(ActionEvent e) {
						dispose();
					}
				});
				cancelButton.setActionCommand("Cancel");
				buttonPane.add(cancelButton);
			}
		}
	}

	protected void save() throws FileNotFoundException, IOException {
		Hashtable<String, String> servers = new Hashtable<String, String>();
		for (int i = 0; i < listModel.size(); i++) {
			ServerEntry serverEntry = (ServerEntry) listModel.elementAt(i);
			servers.put(serverEntry.getServerName(), serverEntry.getValue());
		}
		SybaseBuddyApplication.servers = servers;
		SybaseBuddyApplication.writeServersToFile();
	}

	private void load() {
		listModel.clear();
		for (Enumeration<String> keys = SybaseBuddyApplication.servers.keys(); keys.hasMoreElements();) {
			String key = keys.nextElement();
			String value = SybaseBuddyApplication.servers.get(key);
			ServerEntry serverEntry = new ServerEntry(key, value);
			listModel.addElement(serverEntry);
		}
	}

}
