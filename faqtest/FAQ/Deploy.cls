/// クラウド更新時のデプロイ処理用クラス<br>
/// <pre>
/// ************************************************************************************************
/// 
/// All()メソッド：クラウド用ソース、グローバル、添付ファイルを全部一括でエクスポートできます。
/// 	【使い方】前回エクスポートしたXMLファイルを読み込みエクスポートリストを確認します。
/// 		第1引数：前回エクスポートしたXMLファイルをフルパスで指定　例）/xxx/FAQRefOnly.xml
/// 		第2引数：Deployファイルを置くディレクトリの指定（指定がないor存在しない時はデータベースディレクトリにおきます）
/// 			Installerでは　/usr/FAQsetup/YYYYMMDD　の下に FAQRefOnly.xml、TopicD.xml をおくらしいので
/// 			ファイル名をあわせてます（先頭にyyyymmddをつけてますが、末尾は一緒にしてます）
/// 		第3引数：更新された添付ファイルを取得するため、更新チェック日数を指定します(デフォルト30日指定)。
/// 			ダウンロードファイルは第2引数で確定したディレクトリ/DLs　を作成しその場所にZipごとコピーしてます
/// 				(KB.TopicのFileFlgでチェックできなかったため、ファイルの更新日付でチェックしてます)
/// 
/// Glo()メソッド: グローバル変数のみのエクスポート用
/// 	【使い方】　引数にエクスポート用ディレクトリを指定するだけ（指定無し/存在無しの場合はデータベースディレクトリにおきます）
/// 
/// ************************************************************************************************
/// </pre>
Class FAQ.Deploy
{

/// グローバル変数(^KB.ToipicD)のみのエクスポート
/// 引数：Deploy用ディレクトリ
ClassMethod Glo(deployDir As %String = "")
{
	do ..DirChk(.deployDir)
	set glofile=$ZDATE($H,8)_"TopicD.xml"
	set st=$system.OBJ.Export("KB.TopicD.gbl",deployDir_glofile,.err)
	if $$$ISERR(st) {
		zwrite err
		write !,$system.Status.GetErrorText(st),!
	}
}

/// ソース、グローバル、添付ファイル、全部一括エクスポート＋抽出用メソッド <br>
/// 第1引数：前回のエクスポートファイル　（前回何をエクスポートしたか不明な時に確認のため指定）<br>
/// 第2引数：Deployファイルを置くディレクトリ　（存在しない/指定無しの場合は実行中データベースディレクトリに配置）<br>
/// 		【メモ】<br>
/// 		Installerでクラウド環境では　/usr/FAQsetup/yyyymmdd　がセットアップディレクトリとされている<br>
/// 		セットアップディレクトリ配下に　FAQRefOnly.xml、TopicD.xml　があれば良いらしいのでDeploy側も作成（先頭に日付だけ付与）<br>
/// 第3引数：更新された添付ファイルを取得するため、更新をチェックする日数を指定（n日前以降の更新を取得します）<br>
ClassMethod All(prevFile As %String, deployDir As %String = "", days As %Integer = 30)
{
	// FAQクラウド用ソースコードのエクスポート
	if $get(prevFile)=""!'(##class(%File).Exists(prevFile)) {
		write "第1引数に指定の前回エクスポートしたファイル名を確認してください",!
		quit
	}

	do ..DirChk(.deployDir)
		
	set deployFull=deployDir_$ZDATE($H,8)_"FAQRefOnly.xml"
	do ..PrevExportFile(prevFile,.prevList)
	
	// iFind対応の時、以下不要なので念のため
	if $data(prevList("Text.MecabJapanese2.cls")) {
		kill prevList("Text.MecabJapanese2.cls")
	}
	
	// Deploy用クラスも含めたいので
	if '$data(prevList("FAQ.Deploy")) {
		set prevList("FAQ.Deploy.cls")=""
	}
	
	set st=$system.OBJ.Export(.prevList,.deployFull,"",.err)
	if $$$ISERR(st) {
		zwrite err
		write !,$system.Status.GetErrorText(st),!
		quit
	}
	
	write !!
	//downloadFileの抽出
	set st=..RecentUpdate(days,.downloads)
	if $$$ISERR(st){
		write $system.Status.GetErrorText(st),!
		quit
	}
	// 取得したファイルを現在のDeploy用ディレクトリ以下のサブディレクトリを作りコピー
	set dldir=deployDir_"DLs"
	if '##class(%File).DirectoryExists(dldir) {
		set st=##class(%File).CreateDirectory(dldir)
	}
	if st=0 {
		write "添付ファイル用移動ディレクトリ作成失敗  >> ",dldir,!
		quit
	}
	
	for i=1:1:downloads.Count() {
		set to=##class(%File).NormalizeDirectory(dldir)_##class(%File).GetFilename(downloads.GetAt(i))
		set st=##class(%File).CopyFile(downloads.GetAt(i),to,,.err)
		if st=0 {
			write "ファイルのコピー失敗 >>",downloads.GetAt(i),!
			
		}
	}
	
	//最後に ^KB.TopicD　のエクスポート
	set glofile=$ZDATE($H,8)_"TopicD.xml"
	set st=$system.OBJ.Export("KB.TopicD.gbl",deployDir_glofile,.err)
	if $$$ISERR(st) {
		zwrite err
		write !,$system.Status.GetErrorText(st),!
	}
}

/// Deployディレクトリの存在チェックなど
/// 引数：Deploy用ディレクトリ
ClassMethod DirChk(ByRef deployDir As %String = "")
{
	// deployDirが指定されない場合は、ディレクトリが存在しない場合は、実行中データベースのディレクトリにエクスポートする
	if '##class(%File).DirectoryExists(deployDir) {
		write "指定したディレクトリがないので、データベースディレクトリにエクスポートします　>> 指定ディレクトリ：",deployDir,!
		set deployDir=""
	}
	
	// ********* deployDir はNormalizeDirectry()実行済み **********
	set deployDir=##class(%File).NormalizeDirectory($get(deployDir))
}

/// 最近更新したトピックと関連する添付ファイルを表示
/// 添付ファイルは実際に更新したかどうかは不明なのでファイルの更新タイムスタンプを確認
/// 
/// 第2引数：指定日数以降で更新のあったファイルのフルパスがリストオブジェクトで返される
ClassMethod RecentUpdate(day As %Integer = 30, downloads As %ListOfObjects) As %Status
{
	#dim ex As %Exception.AbstractException
	#dim rset As %SQL.StatementResult
	set st=$$$OK
	try{
		//FAQ用ダウンロードディレクトリの確認
		set dldir=##class(KB.Config).getFTPDirectory()
		set fstart=##class(KB.Config).getAttachedFileName()
		set stmt=##class(%SQL.Statement).%New()
		set sql="select id from KB.Topic where UpdateDate > (CURRENT_DATE-?) order by id desc"
		set st=stmt.%Prepare(sql)
		$$$THROWONERROR(ex,st)

		set rset=stmt.%Execute(day)
		if rset.%SQLCODE<0 {
			throw ##class(%Exception.SQL).CreateFromSQLCODE(rset.%SQLCODE,rset.%Message)
		}
		write "直近 ",day," 日で修正したトピックは以下の通り",!
		while rset.%Next() {
			write rset.id," - "
		}
		
		// FileFlg　が正しくセットされていなそうなのでディレクトリを直接参照する方法に変更
		/*
		set sql="select id from KB.Topic where (UpdateDate > (CURRENT_DATE-?)) and (fileflg=1) order by id desc"
		set st=stmt.%Prepare(sql)
		$$$THROWONERROR(ex,st)

		set rset=stmt.%Execute(day)
		if rset.%SQLCODE<0 {
			throw ##class(%Exception.SQL).CreateFromSQLCODE(rset.%SQLCODE,rset.%Message)
		}
		write !!,"直近 ",day," 日で修正したトピックで添付ファイルがあるトピックは以下の通り",!
		while rset.%Next() {
			set attachfile=##class(%File).NormalizeDirectory(dldir)_fstart_rset.id_".zip"
			set file=##class(%File).%New(attachfile)
			write rset.id," - ファイル名 : ",attachfile,!," ** 作成日付：",$ZDATETIME(file.DateCreated,3),"/ 更新日付：",$ZDATETIME(file.DateModified,3),!
			kill file
		}
		*/
		set st=stmt.%PrepareClassQuery("%File","FileSet")
		set stmt.%SelectMode=1
		set rset=stmt.%Execute(dldir,"*.zip")
		write !!,"直近 ",day," 日で修正したトピックで添付ファイルがあるトピックは以下の通り",!
		set downloads=##class(%ListOfDataTypes).%New()
		while rset.%Next() {
			set filename=rset.%Get("Name")
			set chkdate=$H-day
			if $ZDATETIMEH(rset.%Get("DateModified"),3)>chkdate {
				write filename,!," *** 作成日付 : ",rset.%Get("DateCreated")," / 更新日付 : ",rset.%Get("DateModified"),!
				do downloads.Insert(filename)
			}
		}
		kill rset
	}
	catch ex {
		write ex.DisplayString()
		set st=ex.AsStatus()
	}
	quit st
}

/// 前回エクスポートしたXMLファイルを使用して、エクスポートリストを取得する
ClassMethod PrevExportFile(prevFile As %String, list As %String)
{
	if $get(prevFile)=""!'(##class(%File).Exists(prevFile)) {
		write "第1引数に指定のファイル名を確認してください",!
		quit
	}
	set st=$system.OBJ.Load(prevFile,,.err,.list,1)
	if $$$ISERR(st) {
		zwrite err
		quit
	}
}

}
