B4J=true
Group=Module
ModulesStructureVersion=1
Type=StaticCode
Version=2.18
@EndOfDesignText@

Sub Process_Globals
	Private con As SQL	
	Private pool As ConnectionPool
	Private Exceptions As String
	Private DriverClass As String
	Private JdbcUrl As String	
End Sub

'Sub Initialize
'	Exceptions = ""
'End Sub

Public Sub Init(DBUser As String, DBPassword As String, DBName As String) As Boolean
	Dim Success As Boolean
	Try
		DriverClass = Main.settings.Get("DriverClass")
		JdbcUrl = Main.settings.Get("JdbcUrl")
		If DBName <> "" Then
			JdbcUrl = JdbcUrl.ToLowerCase.Replace("information_schema", DBName)
		End If		
		pool.Initialize(DriverClass, JdbcUrl, DBUser, DBPassword)
		con = pool.GetConnection
		If con.IsInitialized Then
			Success = True
		Else
			Success = False
		End If		
	Catch
		LogError(LastException)
		Exceptions = LastException.Message
		Success = False
	End Try
	If con <> Null And con.IsInitialized Then con.Close
	If pool.IsInitialized Then pool.ClosePool
	Return Success
End Sub

Sub ErrorDesc As String
	Return Exceptions
End Sub

Public Sub GetAllDatabases(DBUser As String, DBPassword As String) As List
	Dim List1 As List
	List1.Initialize
	Try
		DriverClass = Main.settings.Get("DriverClass")
		JdbcUrl = Main.settings.Get("JdbcUrl")
		pool.Initialize(DriverClass, JdbcUrl, DBUser, DBPassword)
		con = pool.GetConnection
		If con.IsInitialized Then						
			Dim qry As String = "SELECT SCHEMA_NAME FROM `SCHEMATA`"			
			Dim res As ResultSet = con.ExecQuery(qry)
			Do While res.NextRow
				List1.Add(res.GetString2(0))
			Loop
		End If
	Catch
		LogError(LastException)
		Exceptions = LastException.Message
	End Try
	If con <> Null And con.IsInitialized Then con.Close
	If pool.IsInitialized Then pool.ClosePool
	Return List1
End Sub

Public Sub GetAllTables(DBUser As String, DBPassword As String, DBName As String) As List
	Dim List1 As List
	List1.Initialize
	Try
		DriverClass = Main.settings.Get("DriverClass")
		JdbcUrl = Main.settings.Get("JdbcUrl")		
		JdbcUrl = JdbcUrl.ToLowerCase.Replace("information_schema", DBName)
		pool.Initialize(DriverClass, JdbcUrl, DBUser, DBPassword)
		con = pool.GetConnection
		If con.IsInitialized Then						
			Dim qry As String = "SHOW TABLES"
			Dim res As ResultSet = con.ExecQuery(qry)
			Do While res.NextRow
				List1.Add(res.GetString2(0))
			Loop	
		End If
	Catch
		LogError(LastException)
		Exceptions = LastException.Message
	End Try
	If con <> Null And con.IsInitialized Then con.Close
	If pool.IsInitialized Then pool.ClosePool
	Return List1
End Sub

Public Sub GetTableData(DBUser As String, DBPassword As String, DBName As String, TableName As String, Limit As Int) As String
	Dim html As String
	Try
		DriverClass = Main.settings.Get("DriverClass")
		JdbcUrl = Main.settings.Get("JdbcUrl")
		JdbcUrl = JdbcUrl.ToLowerCase.Replace("information_schema", DBName)
		pool.Initialize(DriverClass, JdbcUrl, DBUser, DBPassword)
		con = pool.GetConnection
		If con.IsInitialized Then
			Dim qry As String = "SELECT * FROM " & TableName & " LIMIT " & Limit
			html = ExecuteHtmlTable(con, qry, Null)
		End If
	Catch
		LogError(LastException)		
		Exceptions = LastException.Message
	End Try
	If con <> Null And con.IsInitialized Then con.Close
	If pool.IsInitialized Then pool.ClosePool
	Return html
End Sub

Public Sub SQLExecQuery(DBUser As String, DBPassword As String, DBName As String, Statement As String, Limit As Int) As String
	Dim html As String
	Try
		DriverClass = Main.settings.Get("DriverClass")
		JdbcUrl = Main.settings.Get("JdbcUrl")
		JdbcUrl = JdbcUrl.ToLowerCase.Replace("information_schema", DBName)
		pool.Initialize(DriverClass, JdbcUrl, DBUser, DBPassword)
		con = pool.GetConnection
		If con.IsInitialized Then
			If Statement.ToUpperCase.Contains("LIMIT") = False Then Statement = Statement & " LIMIT " & Limit
			html = ExecuteHtmlTable(con, Statement, Null)
		End If
	Catch
		LogError(LastException)
		Exceptions = LastException.Message
	End Try
	If con <> Null And con.IsInitialized Then con.Close
	If pool.IsInitialized Then pool.ClosePool
	Return html
End Sub

Public Sub SQLExecNonQuery(DBUser As String, DBPassword As String, DBName As String, Statement As String) As Boolean
	Dim Success As Boolean
	Try
		DriverClass = Main.settings.Get("DriverClass")
		JdbcUrl = Main.settings.Get("JdbcUrl")
		JdbcUrl = JdbcUrl.ToLowerCase.Replace("information_schema", DBName)
		pool.Initialize(DriverClass, JdbcUrl, DBUser, DBPassword)
		con = pool.GetConnection
		If con.IsInitialized Then
			con.ExecNonQuery(Statement)
			Success = True
		Else
			Success = False
		End If
	Catch
		LogError(LastException)
		Exceptions = LastException.Message
		Success = False
	End Try
	If con <> Null And con.IsInitialized Then con.Close
	If pool.IsInitialized Then pool.ClosePool
	Return Success
End Sub

'Creates a html text that displays the data in a table.
'The style of the table can be changed by modifying HtmlCSS variable.
Public Sub ExecuteHtmlTable(SQL As SQL, Query As String, StringArgs() As String) As String
	Dim sb As StringBuilder
	sb.Initialize
	Try
		Dim cur As ResultSet
		If StringArgs <> Null Then
			cur = SQL.ExecQuery2(Query, StringArgs)
		Else
			cur = SQL.ExecQuery(Query)
		End If
		Log("ExecuteHtmlTable: " & Query)
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
	Catch
		LogError(LastException)
		Exceptions = LastException.Message
	End Try
	Return sb.ToString
End Sub
