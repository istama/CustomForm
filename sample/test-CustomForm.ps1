
.\..\CustomForm.ps1

CustomForm form2 test -padLeft 15 -padRight 15 {
  frame -col 0 -align TopLeft -marginLeft 10 (panel {
    frame -align TopRight -marginBottom 15 (label sample)
    frame -marginBottom 15 (button OK)
    frame (button Cancel)
  })
  frame -col 1 -align TopLeft (panel {
    frame -align TopRight -marginRight 10 -marginTop 7 -marginBottom 7 (label NB原稿オレンジペン入り)
    frame -align MiddleLeft -marginRight 10 -marginTop 7 -marginBottom 7 (label 郵政原稿オレンジペン入り)
    frame -align BottomCenter -marginRight 10 -marginTop 7 -marginBottom 7 (label 新規原稿)
    frame -col 1 -marginTop 7 -marginBottom 7 (button -text +10 -width 50)
    frame -col 1 -marginTop 7 -marginBottom 7 (button -text +10 -width 50)
    frame -col 1 -marginTop 7 -marginBottom 7 (button -text +10 -width 50)
    frame -col 2 -marginTop 7 -marginBottom 7 (button -text +5 -width 50)
    frame -col 2 -marginTop 7 -marginBottom 7 (button -text +5 -width 50)
    frame -col 2 -marginTop 7 -marginBottom 7 (button -text +5 -width 50)
  })
}

$f = Create-Form form2
$f.ShowDialog()
