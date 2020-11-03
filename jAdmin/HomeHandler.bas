B4J=true
Group=Handler
ModulesStructureVersion=1
Type=Class
Version=8.31
@EndOfDesignText@
'Handler class
Sub Class_Globals
	
End Sub

Public Sub Initialize

End Sub

Sub Handle(req As ServletRequest, resp As ServletResponse)
	Dim elements() As String = Regex.Split("/", req.RequestURI)
	If elements.Length > 0 Then
		Select elements(1).ToLowerCase
			Case "logout"
				req.GetSession.Invalidate
				resp.SendRedirect(Main.ROOT_PATH)
				Return
			Case "login" ' Load page
				Dim strMain As String = Utility.LoadTextFile("main.html")
				Dim strView As String
				If req.GetSession.GetAttribute("username") = Null Then
					strView = Utility.LoadTextFile("login.html")
				Else
					strView = Utility.LoadTextFile("index.html")
				End If
				strMain = Utility.BuildView(strMain, strView)
				strMain = Utility.BuildHtml(strMain, Main.settings)
				Utility.ReturnHTML(strMain, resp)
			Case "signin" ' Connect DB
				Dim username As String = req.GetParameter("username").Trim
				Dim password As String = req.GetParameter("password")
				Dim database As String = req.GetParameter("database").Trim
				Dim responeMap As Map
				responeMap.Initialize
				If username = "" Or password = "" Then
					responeMap.Put("errorMessage", "User name or password has no value")
				Else
					Dim success As Boolean = DB.Init(username, password, database)
					If success = True Then						
						responeMap.Put("success", success)
						responeMap.Put("database", database)
						req.GetSession.SetAttribute("username", username)
						req.GetSession.SetAttribute("password", password)
					Else
						If DB.ErrorDesc <> "" Then
							responeMap.Put("errorMessage", DB.ErrorDesc)
						Else
							responeMap.Put("errorMessage", "User name or password does not match")
						End If						
					End If				
				End If
				Dim jg As JSONGenerator
				jg.Initialize(responeMap)
				resp.ContentType = "application/json"
				resp.Write(jg.ToString)				
			Case "selectdatabase"
				Dim username As String = req.GetSession.GetAttribute("username")
				Dim password As String = req.GetSession.GetAttribute("password")
				Dim dbname As String = req.GetParameter("selectdatabase").Trim
				Dim strTable As String
				If dbname.Contains("----------") Then
					strTable = "&nbsp;"
				Else
					Dim tbl As List = DB.GetAllTables(username, password, dbname)
					If tbl.IsInitialized Then
						strTable = "<table class=""table bordered bg-light p-3"">"
						For i = 0 To tbl.Size - 1
							strTable = strTable & "<tr><td><a href=""showtabledata?database=" & dbname & "&table=" & tbl.Get(i) & """>" & tbl.Get(i) & "</a></td></tr>"
						Next
						strTable = strTable & "</table>"
					Else
						'strMain = Utility.BuildTag(strMain, "SELECT", "<option> &nbsp; ---------- &nbsp; </option>")
						'Log("failed")
						strTable = "&nbsp;"
					End If
				End If
				resp.Write(strTable)
			Case "showtabledata"
				Dim username As String = req.GetSession.GetAttribute("username")
				Dim password As String = req.GetSession.GetAttribute("password")
				Dim dbname As String = req.GetParameter("database").Trim
				Dim tbname As String = req.GetParameter("table").Trim
				
				Dim strMain As String = Utility.LoadTextFile("main.html")
				Dim strView As String = Utility.LoadTextFile("index.html")
				strMain = Utility.BuildView(strMain, strView)
				strMain = Utility.BuildHtml(strMain, Main.settings)
				
				Dim success As Boolean = DB.Init(username, password, database)
				If success = True Then
					Dim dbl As List = DB.GetAllDatabases(username, password)
					If dbl.IsInitialized Then
						strMain = Utility.BuildTag(strMain, "SELECT", BuildSelectTable(dbl, dbname))
						strMain = Utility.BuildTag(strMain, "USERNAME", "Username: " & req.GetSession.GetAttribute("username") & " &nbsp; ")
						Dim tbl As List = DB.GetAllTables(username, password, dbname)
						If tbl.IsInitialized Then
							Dim strTable1 As String = "<table class=""table bordered bg-light p-3"">"
							For i = 0 To tbl.Size - 1
								strTable1 = strTable1 & "<tr><td><a href=""showtabledata?database=" & dbname & "&table=" & tbl.Get(i) & """>" & tbl.Get(i) & "</a></td></tr>"
							Next
							strTable1 = strTable1 & "</table>"
							Log(strTable1)
							strMain = strMain.Replace("<div id=""datatables""></div>", strTable1)
						
							Dim strTable2 As String = DB.GetTableData(username, password, dbname, tbname, 10) ' limit to 10 rows
							strMain = strMain.Replace("<div id=""datacolumns""></div>", strTable2)
						Else
							If DB.ErrorDesc <> "" Then
								strMain = strMain.Replace("<div id=""datatables""></div>", "<div id=""errorMessage"">" & DB.ErrorDesc & "</div>")
							Else
								strMain = strMain.Replace("<div id=""datatables""></div>", "<div id=""errorMessage"">No tables found</div>")
							End If							
						End If
					Else
						If DB.ErrorDesc <> "" Then
							strMain = strMain.Replace("<div id=""datatables""></div>", "<div id=""errorMessage"">" & DB.ErrorDesc & "</div>")
						Else
							strMain = strMain.Replace("<div id=""datatables""></div>", "<div id=""errorMessage"">User name or password does not match</div>")
						End If
						strMain = Utility.BuildTag(strMain, "SELECT", "<option> &nbsp; ---------- &nbsp; </option>")
					End If					
				Else
					'Return
					If DB.ErrorDesc <> "" Then
						strMain = strMain.Replace("<div id=""datatables""></div>", "<div id=""errorMessage"">" & DB.ErrorDesc & "</div>")
					Else
						strMain = strMain.Replace("<div id=""datatables""></div>", "<div id=""errorMessage"">User name or password does not match</div>")
					End If
					strMain = Utility.BuildTag(strMain, "SELECT", "<option> &nbsp; ---------- &nbsp; </option>")
				End If
				Utility.ReturnHTML(strMain, resp)
			Case "execute"
				Dim username As String = req.GetSession.GetAttribute("username")
				Dim password As String = req.GetSession.GetAttribute("password")
				Dim dbname As String = req.GetParameter("selectdatabase").Trim
				Dim statement As String = req.GetParameter("statement").Trim
				Dim responeMap As Map
				responeMap.Initialize
				If statement = "" Then
					responeMap.Put("errorMessage", "SQL Command cannot be empty!")
				Else If statement.ToUpperCase.StartsWith("SELECT ") Then
					'DB.Initialize
					Dim strTable2 As String = DB.SQLExecQuery(username, password, dbname, statement, 10) ' limit to 10 rows
					If DB.ErrorDesc <> "" Then
						responeMap.Put("errorMessage", DB.ErrorDesc)
					Else						
						responeMap.Put("datacolumns", strTable2)
						responeMap.Put("success", True)
					End If
				Else
					Dim success As Boolean = DB.SQLExecNonQuery(username, password, dbname, statement)
					If success = True Then
						responeMap.Put("success", success)
					Else
						If DB.ErrorDesc <> "" Then
							responeMap.Put("errorMessage", DB.ErrorDesc)
						Else
							responeMap.Put("errorMessage", "User name or password does not match")
						End If
					End If
				End If
				Dim jg As JSONGenerator
				jg.Initialize(responeMap)
				resp.ContentType = "application/json"
				resp.Write(jg.ToString)
				Return
			Case Else
				Log(elements(1).ToLowerCase)
				'Return
		End Select
	Else
		If req.GetSession.GetAttribute("username") = Null Then
			'req.GetSession.Invalidate
			resp.SendRedirect(Main.ROOT_PATH & "login")
			'Return
		Else
			Dim strMain As String = Utility.LoadTextFile("main.html")
			Dim strView As String = Utility.LoadTextFile("index.html")
			strMain = Utility.BuildView(strMain, strView)
			strMain = Utility.BuildHtml(strMain, Main.settings)
			Dim username As String = req.GetSession.GetAttribute("username")
			Dim password As String = req.GetSession.GetAttribute("password")
			Dim success As Boolean = DB.Init(username, password, "")
			If success = True Then
				Dim dbl As List = DB.GetAllDatabases(username, password)
				If dbl.IsInitialized Then
					strMain = Utility.BuildTag(strMain, "SELECT", BuildSelectTable(dbl, "0"))
					strMain = Utility.BuildTag(strMain, "USERNAME", "Username: " & req.GetSession.GetAttribute("username") & " &nbsp; ")
				Else
					strMain = Utility.BuildTag(strMain, "SELECT", "<option> &nbsp; ---------- &nbsp; </option>")
				End If				
			Else
				'Return
				If DB.ErrorDesc <> "" Then
					strMain = strMain.Replace("<div id=""datatables""></div>", "<div id=""errorMessage"">" & DB.ErrorDesc & "</div>")
				Else
					strMain = strMain.Replace("<div id=""datatables""></div>", "<div id=""errorMessage"">User name or password does not match</div>")
				End If
				strMain = Utility.BuildTag(strMain, "SELECT", "<option> &nbsp; ---------- &nbsp; </option>")
			End If
			Utility.ReturnHTML(strMain, resp)
		End If
	End If
End Sub

Sub BuildSelectTable(Tables As List, Selected As String) As String
	Dim strTags As String = "<select id=""selectdatabase"" class=""form-control"">"
	strTags = strTags & "<option> &nbsp; ---------- &nbsp; </option>"
	For i = 0 To Tables.Size - 1
		strTags = strTags & "<option" 
		If Tables.Get(i) = Selected Then
			strTags = strTags & " selected"
		End If				
		strTags = strTags & ">" & Tables.Get(i) & "</option>"
	Next
	strTags = strTags & "</select>"
	Return strTags
End Sub
