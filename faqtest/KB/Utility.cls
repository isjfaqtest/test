Include %occInclude

/// 
Class KB.Utility
{

/// xmlインポートおよびxmlエクスポートでは、TopicのFileLoc(FileStream)は、交換できない
ClassMethod xmlImport(filename As %String)
{
	// Create a new XML Reader class
	Set reader = ##class(%XML.Reader).%New()
	// Begin processing of the XML input
	Set sc=reader.OpenFile(filename)
	If $$$ISERR(sc) Do $system.OBJ.DisplayError(sc) Quit  
	// Associate a class name with the XML element name
	Do reader.Correlate("Topic","KB.Topic")
	// read KB.Topic objects from xml file
	Set Count=0
	While reader.Next(.kb,.sc) {
		Set Count = Count + 1
	    Set sc=kb.%Save()
	    If $$$ISERR(sc) Do $system.OBJ.DisplayError(sc) Quit  
	}
	If $$$ISERR(sc) Do $system.OBJ.DisplayError(sc) Quit
}

ClassMethod ExecxmlImport(dir As %String)
{
	set fileInfors = ##class(%ResultSet).%New("%File:FileSet")
	set count = 0
	set dirname=^Techinfo("XmlExportDirectory")_"\"_dir
	
	do fileInfors.Execute(dirname)
	while(fileInfors.Next()) {
		set filename = fileInfors.GetData(1)
		set file = $Piece(filename,"\",$Length(filename,"\"))
		if ($Piece(filename,".",2)="xml") {
			do ..xmlImport(filename)
			set count = count + 1
		}
	}

	write count," topic(s) Loaded",!
}

ClassMethod xmlExport(id As %String, fileName As %String)
{
	set writer=##class(%XML.Writer).%New()
	set sc = writer.OutputToFile(fileName)
	If $$$ISERR(sc) Do $system.OBJ.DisplayError(sc) Quit
	set sc=writer.RootElement("KBTopic")
	If $$$ISERR(sc) Do $system.OBJ.DisplayError(sc) Quit
	set tp=##class(KB.Topic).%OpenId(id)
	set writer.ReferencesInline = 1
	set writer.Charset="UTF-8"
	set writer.Format="encoded"
	set sc=writer.Object(tp,"Topic")
	If $$$ISERR(sc) Do $system.OBJ.DisplayError(sc) Quit
	set sc=writer.EndRootElement()
	If $$$ISERR(sc) Do $system.OBJ.DisplayError(sc) Quit
}

ClassMethod ExecxmlExport(startid, endid)
{
	
	set exportdir=^Techinfo("XmlExportDirectory")_"\"_$zdate($h,8)
	
	set st1=##class(%File).DirectoryExists(exportdir)
	if st1=0 {
		set st2 = ##class(%File).CreateDirectory(exportdir)
	}
	
	set expcount=0
	
	for id=startid:1:endid {
		set tp=##class(KB.Topic).%OpenId(id)
		if tp="" quit 
		
		set filename=exportdir_"\Topic"_id_".xml"
		do ..xmlExport(id,filename)
		w filename,!
		set expcount=expcount+1
	}
}

ClassMethod ExecxmlExport1(startID As %String, endID As %String)
{
	set dirName="F:\Public\Tech\FAQ\NewKB\Topics\xml\"
	
	;set endID=startID
	
	set filecount=0
	
	for id=startID:1:endID {
	    set tp=##class(KB.Topic).%OpenId(id)
	    
	    if tp.DeleteFlg'=1 {
		    set topicid=tp.TopicID
		    set categoryid=tp.Category.%Id()
	    	set facilityid=tp.Facility.%Id()
	    	
	    	if categoryid'="" {
		    	set subdir1="Category"_categoryid_"\"
	    	}
	    	else {
		    	set subdir1="Other\"
	    	}
	    	
	    	if facilityid'="" {
		    	set subdir2="Facility"_facilityid_"\"
	    	}
	    	else {
		    	set subdir2="Other\"
	    	}
	    
		    if categoryid=5 {
			    set fileName=dirName_subdir1_"Topic"_topicid_".xml"
	    	}
	    	else {
		    	set fileName=dirName_subdir1_subdir2_"Topic"_topicid_".xml"
	    	}

			kill tp  
			set filecount=filecount+1
			
			w topicid,!

	    	do ..xmlExport(id,fileName)
				
	    } 
    }
    w filecount,!
}

ClassMethod ExecxmlExport2(idlist As %String)
{
	set dirName="P:\Public\Tech\FAQ\NewKB\Topics\xml\"
	
	set filecount=0
	
	for i=1:1:$listlength(idlist) {
		
		set id=$list(idlist,i)
	    set tp=##class(KB.Topic).%OpenId(id)
	    
	    if tp.DeleteFlg'=1 {
		    set topicid=tp.TopicID
		    set categoryid=tp.Category.%Id()
	    	set facilityid=tp.Facility.%Id()
	    	
	    	if categoryid'="" {
		    	set subdir1="Category"_categoryid_"\"
	    	}
	    	else {
		    	set subdir1="Other\"
	    	}
	    	
	    	if facilityid'="" {
		    	set subdir2="Facility"_facilityid_"\"
	    	}
	    	else {
		    	set subdir2="Other\"
	    	}
	    
		    if categoryid=5 {
			    set fileName=dirName_subdir1_"Topic"_topicid_".xml"
	    	}
	    	else {
		    	set fileName=dirName_subdir1_subdir2_"Topic"_topicid_".xml"
	    	}

			kill tp  
			set filecount=filecount+1
			
			w topicid,!,fileName,!

	    	do ..xmlExport(id,fileName)
				
	    } 
    }
    w filecount,!
}

ClassMethod ExecxmlExportbk(startID, endID)
{
	;set dirName="F:\Public\Tech\FAQ\NewKB\Topics\xml\"
	
	set dirName="D:\MyISC\FAQ_Project\Topics\xml\"
	
	for id=startID:1:endID {
		;set x1=##class(KB.Topic).%OpenId(id)
	   	set fileName=dirName_"Topic"_id_".xml"
		do ..xmlExport(id,fileName)
	}
}

ClassMethod convertAccent(string As %String) As %String
{
	set output = ""
	for i = 1:1:$length(string) {
		set char = $extract(string,i)
		if $data(^KB.accent($extract(string,i))) set char = ^KB.accent($extract(string,i))
		set output = output_char
	}
	quit output
}

ClassMethod xmlImportOld(fileName As %String)
{
	// Create a new XML Reader class
	Set reader = ##class(%XML.Reader).%New()
	// Begin processing of the XML input
	Set sc=reader.OpenFile(fileName)
	If $$$ISERR(sc) Do $system.OBJ.DisplayError(sc) Quit  
	// Associate a class name with the XML element name
	Do reader.Correlate("problem","KB.OldTopic")
	// read KB.Topic objects from xml file
	Set Count=0
	While reader.Next(.kb,.sc) {
		Set Count = Count + 1
	    Set sc=kb.%Save()
	    If $$$ISERR(sc) Do $system.OBJ.DisplayError(sc) Quit  
	}
	If $$$ISERR(sc) Do $system.OBJ.DisplayError(sc) Quit
}

ClassMethod ExecxmlImport2(dir As %String)
{
	set dir1Infors = ##class(%ResultSet).%New("%File:FileSet")
	set dir2Infors = ##class(%ResultSet).%New("%File:FileSet")
	set fileInfors = ##class(%ResultSet).%New("%File:FileSet")
	set count1 = 0
	set count2 = 0
	
	do dir1Infors.Execute(dir)
	while(dir1Infors.Next()) {
		set dir1name = dir1Infors.GetData(1)
		write !,dir1name," : ",!
		do dir2Infors.Execute(dir1name)
		while(dir2Infors.Next()) {
			set dir2name = dir2Infors.GetData(1)
			do fileInfors.Execute(dir2name)
			while(fileInfors.Next()) {
				set filename = fileInfors.GetData(1)
				set file = $Piece(filename,"\",$Length(filename,"\"))
				if ($Piece(filename,".",$Length(filename,"."))="xml") && ($Extract(file,1,4)="FAQ2"){
					do ..xmlImportOld(filename)
					w file,!
					set count1 = count1 + 1
					set count2 = count2 + 1
				}
			}
		}
		write count2, "topic(s)",!
		set count2 = 0
	}
	write !,count1," topic(s) Loaded",!
}

ClassMethod ModFilename(startID As %String, endID As %String)
{
	set attachedpath="C:\InterSystems\Cache20102\CSP\faq\downloads\"
	
	set f=##class(%File).%New()
	
	for i=startID:1:endID {
		set topic=##class(KB.Topic).%OpenId(i) 
		set fileloc1=topic.FileLoc1
		set filename1=fileloc1.Filename
		set fileloc2=topic.FileLoc2
		set filename2=fileloc2.Filename
		set fileloc3=topic.FileLoc3
		set filename3=fileloc3.Filename
		
		If (filename1'="")&($find(filename1,"\")=0) {
			set mod1=$TR(filename1,$C(0),"\")
			set fname1=f.GetFilename(mod1)
			set mod2=attachedpath_i_"\"_fname1
			set fileloc1.Filename=mod2
			set mod1="",mod2=""
		}
		

		If (filename2'="")&($find(filename2,"\")=0) {
			set mod1=$TR(filename2,$C(0),"\")
			set fname2=f.GetFilename(mod1)
			set mod2=attachedpath_i_"\"_fname2
			set fileloc2.Filename=mod2
			set mod1="",mod2=""

		}

		If (filename3'="")&($find(filename3,"\")=0) {
			set mod1=$TR(filename3,$C(0),"\")
			set fname3=f.GetFilename(mod1)
			set mod2=attachedpath_i_"\"_fname3
			set fileloc3.Filename=mod2
			set mod1="",mod2=""
		}
				
		set st=topic.%Save()
		
		;k fileloc1,fileloc2,fileloc3,filename1,filename2,filename3,fname1,fname2,fname3,mod1,mod2
		
	}
}

ClassMethod SetFileFlg(startID, endID)
{
	for i=startID:1:endID {
		
		set tp=##class(KB.Topic).%OpenId(i)
		
		if tp.FileLoc1.Size'=0 {
			set tp.FileFlg1=1
		}
		
		if tp.FileLoc2.Size'=0 {
			set tp.FileFlg2=1
		}

		if tp.FileLoc3.Size'=0 {
			set tp.FileFlg3=1
		}
		
		set st=tp.%Save()
	}
}

ClassMethod SetTopicID(startID As %String, endID As %String)
{
	for i=startID:1:endID {
		
		set tp=##class(KB.Topic).%OpenId(i)
		if tp'="" {
			if tp.Product.%Id()=1 {
				set tp.TopicSubID=$translate($justify(tp.TopicSubID,3)," ","0")
				set tp.TopicID="G-"_tp.TopicSubID
			}else {
				set tp.TopicID=$translate($justify(i,3)," ","0")
			}
			set st=tp.%Save()
		}
		
	}
}

ClassMethod CopyFilename(startID, endID)
{
	for i=startID:1:endID {
		set topic=##class(KB.Topic).%OpenId(i) 
		set fileloc1=topic.FileLoc1
		set filename1=fileloc1.Filename
		set fileloc2=topic.FileLoc2
		set filename2=fileloc2.Filename
		set fileloc3=topic.FileLoc3
		set filename3=fileloc3.Filename
		
		set topicbk=##class(KB.Topicbk).%OpenId(i) 
		set filelocbk1=topicbk.FileLoc1
		set filenamebk1=filelocbk1.Filename
		set filelocbk2=topicbk.FileLoc2
		set filenamebk2=filelocbk2.Filename
		set filelocbk3=topicbk.FileLoc3
		set filenamebk3=filelocbk3.Filename
		
		If (filename1'="")&(filenamebk1'="") {
			set fileloc1.Filename=filenamebk1
		}
		
		If (filename2'="")&(filenamebk2'="") {
			set fileloc2.Filename=filenamebk2
		}

		If (filename3'="")&(filenamebk3'="") {
			set fileloc3.Filename=filenamebk3
		}

		set st=topic.%Save()

	}
}

// 旧コード→新コードへ

ClassMethod ChangeFacility() As %Status
{
	set faci7=##class(KB.Facility).%OpenId(7)
	set faci8=##class(KB.Facility).%OpenId(8)
	set faci9=##class(KB.Facility).%OpenId(9)
	set faci10=##class(KB.Facility).%OpenId(10)
	
	for i=1:1:248 {
		w i,!
		set topic=##class(KB.Topic).%OpenId(i)
		if topic'="" {
			if topic.Facility.%Id()=7 {
				set topic.Facility=faci8
			}elseif topic.Facility.%Id()=8 {
				set topic.Facility=faci9
			}elseif topic.Facility.%Id()=9 {
				set topic.Facility=faci10
			}
		}
	}
}

// Version設定方法を変更したため、既存データを加工

ClassMethod SetVersion() As %Status
{
	set Idlist=$lb(32,33,34,35,36,37,38,39,48,50,58,73,74,75,76,107,109,110,121,124,126,128,133,140,141,145,146,148,149,150,152,153,154,156,157,159,163,170,177,178,180,182,185,188,189,190,191,192,196,197,209,212,213,214,217,218,219,221)
	set SVlist=$lb(6,7,7,7,7,7,7,7,6,10,6,6,6,6,6,6,6,6,7,6,6,7,6,7,7,7,6,6,6,6,7,6,7,7,9,6,9,9,9,9,7,9,9,7,7,11,11,9,7,7,11,9,9,7,11,11,11,7)
	set EVlist=$lb(6,"","","","","","","",6,"",6,6,6,6,6,6,6,6,"",6,6,10,6,"","","",6,6,6,6,"",6,"","","",6,"","","","","","","","","","","","","","","","","","","","","","")
	
	for i=1:1:58 {
		set tpid=$list(Idlist,i)
		set svid=$list(SVlist,i)
		set evid=$list(EVlist,i)
		
		set tp=##class(KB.Topic).%OpenId(tpid)
		
		if svid'="" {
			set sv=##class(KB.Version).%OpenId(svid)
		}else{
			set sv=""
		}
		
		if evid'=""{
			set ev=##class(KB.Version).%OpenId(evid)
		}else{
			set ev=""
		}
		
		set tp.StartVersion=sv
		set tp.EndVersion=ev
		
		set st=tp.%Save()
	}
	
	quit st
}

ClassMethod RenameFiles(dir, wildcard) As %Status
{
	set filelist=##class(%ResultSet).%New("%File:FileSet")
	set st=filelist.Execute(dir,wildcard)
	while filelist.Next() {
		set filepath = filelist.GetData(1)
		set difdepth = $LENGTH(filepath,"\")
		set filename = $PIECE(filepath,"\",difdepth)
		set newfilename = "Attached"_filename
		set cmd = "rename "_filepath_" "_newfilename
		set sc = $ZF(-1,"rename "_filepath_" "_newfilename)
		//if sc'=0 quit
	}
	
	quit sc
}

ClassMethod SetVersionRange(tid) As %Status
{
	w tid,":"
	set topic=##class(KB.Topic).%OpenId(tid)
	
	if topic'="" {
		
		if topic.StartVersion'= "" {
			set startname=topic.StartVersion.ExternalVersion
		}

		if topic.EndVersion'= "" {
			set endname=topic.EndVersion.ExternalVersion
		}

		if topic.StartVersion'="" {
			if topic.EndVersion'="" {
				if topic.StartVersion=topic.EndVersion {
					set topic.VersionRange=startname
				}else{
					set topic.VersionRange=startname_" ～ "_endname
				}
			}else{
				set topic.VersionRange=startname_" ～"
			}
 		}elseif topic.EndVersion'="" {
			set topic.VersionRange=" ～ "_endname
 		}else {
			set topic.VersionRange=""
 		}
 		
 		w topic.VersionRange,":"
 		
 		set st = topic.%Save()
 		
 		w st,!
	}
}

ClassMethod SetOpenDate() As %Status
{
	for i=1:1:^KB.TopicD {
		set tp=##class(KB.Topic).%OpenId(i)
		
		if $ISOBJECT(tp)'=1 quit
		
		if tp.WebFlg=1 {
			set tp.OpenDate=+$h
			set st=tp.%Save()
		}
	}
}

/*ClassMethod TopicRefCount() As %Status
{
	&sql(select sum(reffreq) into :topicrefcount from KB.Topic)
	
	if (SQLCODE=0) {
		set yesterday=$zdate($h-1,8)
		//前日分のトピック参照数を算出
		set ^AccessCount(yesterday,"TopicRefCount") = topicrefcount- $Get(^AccessCount("TopicRefTotal"))
		//積算トータル参照数をセット
		set ^AccessCount("TopicRefTotal") = topicrefcount
	}
}
*/

/*
ClassMethod ClearUsersVoice() As %Status
{
	for i=1:1:^KB.TopicD {
		set tp=##class(KB.Topic).%OpenId(i)
		if tp {
			set tp.UsersVoice=""
			set st=tp.%Save()
		}
	}
}
*/

/*
新規に追加されたトピック用に、
UsersVoiceオブジェクトを作成し、セットする。
トピックの更新後に必ず実行。
*/
ClassMethod CreateUsersVoice() As %Status
{
	set tSC = $$$OK
	for i=^KB.UsersVoiceD+1:1:^KB.TopicD {
		w "check:",i,"-"
		set uv=##class(UsersVoice).%New()
		set tp=##class(KB.Topic).%OpenId(i)
		if tp {
			//トピックにUsersVoiceオブジェクトが設定されていない場合＝新規トピックの場合は、
			//新規作成したUsersVoiceオブジェクトをセット。
			set tp.UsersVoice=uv
			set uv.TopicId=i
			set tSC=tp.%Save()
			w i,"(new)",!
		}
		else {
			//トピックの番号が抜けている場合は、UsersVoiceのTopicIdをN/Aで作成
			//(トピックのIDとUsersVoiceのIDを同じにするため)
			set uv.TopicId="N/A"
			set tSC=uv.%Save()
			w i,"(N/A)",!
		}
		
	}
	quit tSC
}

ClassMethod ShowVersion() As %String
{
	quit "1.0.011"
}

ClassMethod FindKatakanaKeywords() As %Status
{
	set counter = 0
	kill ^katakanawords
	for i=1:1:^KB.TopicD {
		set topic=##class(KB.Topic).%OpenId(i)
		
		if $ISOBJECT(topic)'=1 continue
		
		Set title = topic.Title
		Set wakatititle = ##class(Text.MecabJapanese2).SeparateWords(title)
		Set pc = $Length(wakatititle," ")
		For j=1:1:pc {
			Set piece = $Piece(wakatititle," ",j)
			If (($ascii($Extract(piece,1)) > 12449) && ($ascii($Extract(piece,1)) < 12541)) {
				set ^katakanawords($increment(counter)) = piece
			}
		}

		Set description = topic.Description
		Set wakatidescription = ##class(Text.MecabJapanese2).SeparateWords(description)
		Set pc = $Length(wakatidescription," ")
		For j=1:1:pc {
			Set piece = $Piece(wakatidescription," ",j)
			If (($ascii($Extract(piece,1)) > 12449) && ($ascii($Extract(piece,1)) < 12541)) {
				set ^katakanawords($increment(counter)) = piece
			}
		}
	}
	Quit $$$OK
}

}
