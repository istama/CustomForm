
.\..\CustomForm.ps1

CustomForm form1 test {
  frame -col 0 -align center {
    label sample
    button OK
    button Cancel
  }
  frame -col 1 -tail {
    label sample2
  }
}

$f = Create-Form form1
$f.ShowDialog()
