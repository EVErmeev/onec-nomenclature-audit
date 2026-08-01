&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	IncludeDeletionMark = False;
	IncludeGroups = False;
	OnlyWithProblems = True;
	MaxRowCount = 1000;
EndProcedure

&AtClient
Procedure Generate(Command)
	Settings = New Structure;
	Settings.Insert("IncludeDeletionMark", IncludeDeletionMark);
	Settings.Insert("IncludeGroups",       IncludeGroups);
	Settings.Insert("OnlyWithProblems",    OnlyWithProblems);
	Settings.Insert("MaxRowCount",         MaxRowCount);
	GenerateOnServer(Settings);
EndProcedure

&AtServer
Procedure GenerateOnServer(Settings)
	Cancel = False;
	ReportObject = FormAttributeToValue("Object");
	If ReportObject <> Undefined Then
		ReportObject.GenerateReport(Result, Settings, Cancel);
	EndIf;
EndProcedure