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
				'Return
			Case "signin" ' Connect DB
				Dim username As String = req.GetParameter("username").Trim
				Dim password As String = req.GetParameter("password")
				Dim success As Boolean
				Dim responeMap As Map
				responeMap.Initialize
				If username = "" Or password = "" Then
					responeMap.Put("errorMessage", "User name or password has no value")
					'Return
				Else
					success = DB.init(username, password)
					responeMap.Put("success", success)
					If success = True Then
						req.GetSession.SetAttribute("username", username)
						req.GetSession.SetAttribute("password", password)
					Else
						responeMap.Put("errorMessage", "User name or password does not match")
					End If
				End If
				Dim jg As JSONGenerator
				jg.Initialize(responeMap)
				resp.ContentType = "application/json"
				resp.Write(jg.ToString)
				Return
			Case "selectdatabase"
				Dim username As String = req.GetSession.GetAttribute("username")
				Dim password As String = req.GetSession.GetAttribute("password")
				Dim dbname As String = req.GetParameter("selectdatabase").Trim
				If dbname.Contains("----------") Then
					resp.Write("")
					Return
				End If
				Dim tbl As List = DB.GetAllTables(username, password, dbname)
				If tbl.IsInitialized Then
					Dim strTable As String = "<table class=""table bordered bg-light p-3"">"
					For i = 0 To tbl.Size - 1
						strTable = strTable & "<tr><td><a href=""showtabledata?database=" & dbname & "&table=" & tbl.Get(i) & """>" & tbl.Get(i) & "</a></td></tr>"
					Next
					strTable = strTable & "</table>"
					resp.Write(strTable)
				Else
					'strMain = Utility.BuildTag(strMain, "SELECT", "<option> &nbsp; ---------- &nbsp; </option>")
					'Log("failed")
					resp.Write("")
				End If
			Case "showtabledata"
				Dim username As String = req.GetSession.GetAttribute("username")
				Dim password As String = req.GetSession.GetAttribute("password")
				Dim dbname As String = req.GetParameter("database").Trim
				Dim tbname As String = req.GetParameter("table").Trim
				
				Dim strMain As String = Utility.LoadTextFile("main.html")
				Dim strView As String = Utility.LoadTextFile("index.html")
				strMain = Utility.BuildView(strMain, strView)
				strMain = Utility.BuildHtml(strMain, Main.settings)
				Dim success As Boolean = DB.init(username, password)
				If success = False Then
					Return
				End If
				Dim dbl As List = DB.GetAllDatabases
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
					End If
				Else
					strMain = Utility.BuildTag(strMain, "SELECT", "<option> &nbsp; ---------- &nbsp; </option>")
				End If
				Utility.ReturnHTML(strMain, resp)
			Case "execute"
				Dim username As String = req.GetSession.GetAttribute("username")
				Dim password As String = req.GetSession.GetAttribute("password")
				Dim dbname As String = req.GetParameter("selectdatabase").Trim
				Dim statement As String = req.GetParameter("statement").Trim
				Dim success As Boolean
				success = DB.SQLExecNonQuery(username, password, dbname, statement)
				Dim responeMap As Map
				responeMap.Initialize
				responeMap.Put("success", success)
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
			Dim success As Boolean = DB.init(username, password)
			If success = False Then
				Return
			End If
			Dim dbl As List = DB.GetAllDatabases
			If dbl.IsInitialized Then
				strMain = Utility.BuildTag(strMain, "SELECT", BuildSelectTable(dbl, "0"))
				strMain = Utility.BuildTag(strMain, "USERNAME", "Username: " & req.GetSession.GetAttribute("username") & " &nbsp; ")
			Else
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