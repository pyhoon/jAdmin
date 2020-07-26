B4J=true
Group=Module
ModulesStructureVersion=1
Type=StaticCode
Version=8.1
@EndOfDesignText@

Sub Process_Globals

End Sub

Sub BuildHtml(strHTML As String, Config As Map) As String
	' Replace variables with $KEY$ with new content from Map
	strHTML = WebUtils.ReplaceMap(strHTML, Config)
	Return strHTML
End Sub

Sub BuildView(strHTML As String, View As String) As String
	' Replace Section with @VIEW@ with new content
	strHTML = strHTML.Replace("@VIEW@", View)
	Return strHTML
End Sub

Sub BuildTag(strHTML As String, Tag As String, Value As String) As String
	' Replace Section with @VIEW@ with new content
	strHTML = strHTML.Replace("@" & Tag & "@", Value)
	Return strHTML
End Sub

Sub LoadTextFile(FileName As String) As String
	Return File.ReadString(File.DirAssets, FileName)
End Sub

Sub LoadSettings(FileName As String) As Map
	Return File.ReadMap(File.DirApp, FileName)
End Sub

Sub ReturnHTML(str As String, resp As ServletResponse)
	resp.ContentType = "text/html"
	resp.Write(str)
End Sub