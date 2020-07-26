B4J=true
Group=Module
ModulesStructureVersion=1
Type=StaticCode
Version=2.18
@EndOfDesignText@

Sub Process_Globals
	'Public pool As ConnectionPool
	Private pool As ConnectionPool	
End Sub

Public Sub init(DBUser As String, DBPassword As String) As Boolean
	Dim JdbcUrl As String
	Dim DriverClass As String
	Try
		JdbcUrl = Main.settings.Get("JdbcUrl")
		DriverClass = Main.settings.Get("DriverClass")
		pool.Initialize(DriverClass, JdbcUrl, DBUser, DBPassword)
		Dim sql1 As SQL = pool.GetConnection
		If sql1.IsInitialized Then
			sql1.Close
			Return True
		End If
		sql1.Close
		Return False
	Catch
		Log(LastException)
		'sql1.Close
		Return False
	End Try
End Sub

Public Sub GetAllDatabases As List
	Dim list1 As List
	Try
		Dim sql1 As SQL = pool.GetConnection		
		Dim res As ResultSet
		Dim qry As String
		qry = "SELECT SCHEMA_NAME FROM `SCHEMATA`"
		list1.Initialize
		res = sql1.ExecQuery(qry)
		Do While res.NextRow
			'Log(res.GetString("SCHEMA_NAME"))
			list1.Add(res.GetString2(0))
		Loop
		sql1.Close
		Return list1
	Catch
		Log(LastException)
		Return Null
	End Try
End Sub

Public Sub GetAllTables(DBUser As String, DBPassword As String, DBName As String) As List
	Dim list1 As List
	Dim JdbcUrl As String
	Dim DriverClass As String
	Try
		DriverClass = Main.settings.Get("DriverClass")
		JdbcUrl = Main.settings.Get("JdbcUrl")		
		JdbcUrl = JdbcUrl.Replace("information_schema", DBName)		
		pool.Initialize(DriverClass, JdbcUrl, DBUser, DBPassword)
		Dim sql1 As SQL = pool.GetConnection
		If sql1.IsInitialized Then
			Dim res As ResultSet
			Dim qry As String
			qry = "SHOW TABLES"
			list1.Initialize
			res = sql1.ExecQuery(qry)
			Do While res.NextRow
				'Log(res.GetString("SCHEMA_NAME"))
				list1.Add(res.GetString2(0))
			Loop	
		End If
		sql1.Close
		Return list1
	Catch
		Log(LastException)
		Return Null
	End Try
End Sub

Public Sub GetTableData(DBUser As String, DBPassword As String, DBName As String, TableName As String, Limit As Int) As String
	Dim JdbcUrl As String
	Dim DriverClass As String
	Try
		DriverClass = Main.settings.Get("DriverClass")
		JdbcUrl = Main.settings.Get("JdbcUrl")
		JdbcUrl = JdbcUrl.Replace("information_schema", DBName)
		pool.Initialize(DriverClass, JdbcUrl, DBUser, DBPassword)
		Dim sql1 As SQL = pool.GetConnection
		If sql1.IsInitialized Then
			Dim qry As String = "SELECT * FROM " & TableName & " LIMIT " & Limit
			Dim html As String = ExecuteHtmlTable(sql1, qry, Null, Limit)
			sql1.Close
			Return html
		End If
		Return ""
	Catch
		Log(LastException)
		Return ""
	End Try	
End Sub

Public Sub SQLExecNonQuery(DBUser As String, DBPassword As String, DBName As String, Statement As String) As Boolean
	Dim JdbcUrl As String
	Dim DriverClass As String
	Try
		DriverClass = Main.settings.Get("DriverClass")
		JdbcUrl = Main.settings.Get("JdbcUrl")
		JdbcUrl = JdbcUrl.Replace("information_schema", DBName)
		pool.Initialize(DriverClass, JdbcUrl, DBUser, DBPassword)
		Dim sql1 As SQL = pool.GetConnection
		If sql1.IsInitialized Then
			sql1.ExecNonQuery(Statement)
		End If
		sql1.Close
		Return True
	Catch
		Log(LastException)
		Return False
	End Try
End Sub

'Creates a html text that displays the data in a table.
'The style of the table can be changed by modifying HtmlCSS variable.
Public Sub ExecuteHtmlTable(SQL As SQL, Query As String, StringArgs() As String, Limit As Int) As String
	Dim cur As ResultSet
	If StringArgs <> Null Then
		cur = SQL.ExecQuery2(Query, StringArgs)
	Else
		cur = SQL.ExecQuery(Query)
	End If
	Log("ExecuteHtmlTable: " & Query)
																														 
	Dim sb As StringBuilder
	sb.Initialize
	'sb.Append("<html><body>").Append(CRLF)
	'sb.Append("<style type='text/css'>").Append(HtmlCSS).Append("</style>").Append(CRLF)
	sb.Append("<table class=""table""><thead>")'.Append(CRLF)
	For i = 0 To cur.ColumnCount - 1
		sb.Append("<th>").Append(cur.GetColumnName(i)).Append("</th>")
	Next
	sb.Append("</thead>")
	
	Dim row As Int
	Do While cur.NextRow
		sb.Append("<tr>")
		For i = 0 To cur.ColumnCount - 1
			sb.Append("<td>")
			sb.Append(cur.GetString2(i))
			sb.Append("</td>")
		Next
		sb.Append("</tr>").Append(CRLF)
		row = row + 1
	Loop
	cur.Close
	sb.Append("</table>")
	Return sb.ToString
End Sub