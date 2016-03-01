
#
# Windowsフォームを簡単に記述するためのライブラリ
#

Set-StrictMode -Version Latest

# .NETのライブラリをインポート
[void][reflection.assembly]::LoadWithPartialName("System.Windows.Forms")

# クラス定義を格納するための領域
$global:__FormClassTable__ = @{}

# クラス定義
function global:CustomForm {
  param(
    [Parameter(Mandatory=$true, Position=1)]
    [string] $type,
    [Parameter(Mandatory=$true, Position=2)]
    [string] $text,
    [Parameter(Mandatory=$true, Position=3)]
    [scriptblock] $definition,
    [int] $padTop=10,
    [int] $padBottom=10,
    [int] $padLeft=10,
    [int] $padRight=10
  )
  if ($global:__FormClassTable__[$type]) {
    throw "type $type is already defined"
  }

  $hash = @{
    text=$text
    definition=$definition
    padTop=$padTop
    padBottom=$padBottom
    padLeft=$padLeft
    padRight=$padRight
  }

  # クラス定義を実行して破棄する
  # こうすることでクラス定義に構文エラーがあった場合、
  # インスタンス生成時ではなくクラス定義の時点でエラー検出できる
  __new__formInstance $hash > $null

  $global:__FormClassTable__[$type] = $hash
}

# インスタンス生成メソッドのキーワードを作成
function global:Create-Form ([string] $type) {
  $hash = $__FormClassTable__[$type]
  if (! $hash) {
    thorw "$type is undefined"
  }

  __new__formInstance $hash
}

# クラス定義を削除するためのヘルパー関数
function Remove-Class ([string] $type) {
  $__FormClassTable__.remove($type)
}

# クラス定義が記述されたスクリプトブロックを実行し、
# 合成メンバオブジェクトのコレクションを返すヘルパー関数を用意する
function global:__new__formInstance ([hashtable] $hash) {
  #
  # .NETライブラリの簡易名
  #
  $CONTENT_ALIGNMENT = [System.Drawing.ContentAlignment]

  #
  # ヘルパーメソッドの定義
  #

  # 値をチェックし条件に当てはまらない場合はエラーメッセージを投げる
  function assert ([scriptblock] $require, [string] $msg) {
    if (! (&$require)) { throw $msg }
  }

  # エラーメッセージを投げるヘルパーメソッド
  function elementSyntax($msg) {
    throw "class element syntax: $msg"
  }

  # コレクション内の最大値を取得する
  function max ($array, [scriptblock] $handle) {
    ($array | foreach $handle | Measure-Object -max).Maximum
  }
  # コレクション内の最大値を取得する
  function sum ($array, [scriptblock] $handle) {
    ($array | foreach $handle | Measure-Object -sum).Sum
  }

  # ラベルのサイズと表示位置をセットする
  function align-labelText {
    param(
      [System.Windows.Forms.Label] $label,
      [int] $width,
      [int] $height,
      $align
    )
    $label.AutoSize = $false
    $label.Size = New-Object System.Drawing.Size($width, $height)
    $label.TextAlign = $align
  }

  # コントロールのサイズをセット
  function Set-SizeToControl {
    param(
      [System.Windows.Forms.Control] $control,
      [int] $width,
      [int] $height
    )
    if ($width -le -1)  { $width = $control.Size.Width }
    if ($height -le -1) { $height = $control.Size.Height }
    $control.Size = New-Object System.Drawing.Size($width, $height)
  }

  #
  # コントロールの定義
  #

  # ボタンを作成
  function button ([string] $text="", [int] $width=-1, [int] $height=-1, [scriptblock] $event) {
    $b      = New-Object System.Windows.Forms.Button
    $b.Text = $text
    Set-SizeToControl $b $width $height
    $b.add_click($event)
    $b
  }

  # ラベルを生成
  function label([string] $text="") {
    $l          = New-Object System.Windows.Forms.Label
    $l.Text     = $text
    $l.AutoSize = $true
    $l
  }

  # フレーム
  function frame {
    param(
      [Parameter(Mandatory=$true, Position=1)]
      [scriptblock] $definition,
      [int] $col=0,
      [int] $padTop=10,
      [int] $padBottom=10,
      [int] $padLeft=10,
      [int] $padRight=10,
      [int] $elementsMargin=5,
      [string] $align="head",
      [switch] $horizontal,
      [switch] $tail
    )

    assert { $col -ge 0 } "col must be more than 0. / $col"
    assert {
      $align -eq "head" -or $align -eq "center" -or $align -eq "tail"
    } "align is invalid value. / $align"

    $ctrls = &$definition
    $panel = New-Object System.Windows.Forms.Panel

    $x = $padLeft
    $y = $padTop
    $width = 0
    $height = 0

    # 座標をセットせずに先にパネルに追加だけする理由は、
    # Labelはパネルに追加しないと、サイズが確定されないため、
    foreach ($c in $ctrls) {
      $panel.controls.Add($c)
    }

    # コントロールの座標をセットする
    if ($horizontal) {
      $maxHeight = max $ctrls { $_.Size.Height }
      # コントロールを横に並べる
      foreach ($c in $ctrls) {
        if ($c -is [System.Windows.Forms.Label]) {
          $lAlign = $(
            if ($align -eq "center") { $CONTENT_ALIGNMENT::MiddleLeft }
            elseif ($align -eq "tail") { $CONTENT_ALIGNMENT::BottomLeft }
            else { $CONTENT_ALIGNMENT::TopLeft }
          )
          align-labelText $c $c.Size.Width $maxHeight $lAlign
        }
        $c.Location = New-Object System.Drawing.Point($x, $y)

        $x += $c.Size.Width + $elementsMargin
        if ($c.Size.Height -gt $height) {
          $height = $c.Size.Height
        }
      }
     $width = $x - $elementsMargin + $padRight
     $height += $padBottom
    }
    else {
      $maxWidth = max $ctrls { $_.Size.Width }
      # コントロールを縦に並べる
      foreach ($c in $ctrls) {
        if ($c -is [System.Windows.Forms.Label]) {
          $lAlign = $(
            if ($align -eq "center") { $CONTENT_ALIGNMENT::TopCenter }
            elseif ($align -eq "tail") { $CONTENT_ALIGNMENT::TopRight }
            else { $CONTENT_ALIGNMENT::TopLeft }
          )
          align-labelText $c $maxWidth $c.Size.Height $lAlign
        }
        $c.Location = New-Object System.Drawing.Point($x, $y)

        $y += $c.Size.Height + $elementsMargin
        if ($c.Size.Width -gt $width) {
          $width = $c.Size.Width
        }
      }
      $height = $y - $elementsMargin + $padBottom
      $width += $padRight
    }

    $panel.Size = New-Object System.Drawing.Size($width, $height)
    @{
      panel = $panel
      col   = $col
      tail  = $tail
    }
  }

  #
  # 関数本文の開始
  #

  # 各フレームのオブジェクトを取得
  $frames = @(
    &$hash.definition |
    foreach { $id=0 } {
      if (! $_ ) { write-error "invalid frame" }
      else {
        $_.id = $id++
        $_
      }
    } |
    sort { $_.col }, { $_.id } |
    foreach { $row = 0; $col = 0 } {
      # 各フレームに行要素を追加
      if ($_.col -ne $col) {
        $row = 0
        $col = $_.col
      }
      $_.row = $row++
      $_
    })

  # 各行と列の長さを取得
  $widthList = @()
  $heightList = @()
  foreach ($f in $frames) {
    if ($f.col -ge $widthList.count) {
      $widthList += $f.panel.Width
    }
    elseif ($f.panel.Width -gt $widthList[$f.col]) {
      $widthList[$f.col] = $f.panel.Width
    }

    if ($f.row -ge $heightList.count) {
      $heightList += $f.panel.Height
    }
    elseif ($f.panel.Height -gt $heightList[$f.row]) {
      $heightList[$f.row] = $f.panel.Height
    }
  }

  # 各行と列の開始座標を取得
  $xLocationList = @(
    $hash.padLeft
    if ($widthList.count -gt 0) {
      foreach ($i in 0..($widthList.count-1)) {
        $hash.padLeft + (sum $widthList[0..$i] { $_ })
      }
    })
  $yLocationList = @(
    $hash.padTop
    if ($heightList.count -gt 0) {
      foreach ($i in 0..($heightList.count-1)) {
        $hash.padTop + (sum $heightList[0..$i] { $_ })
      }
    })

  # フォームにフレームを追加する
  $form = New-Object System.Windows.Forms.Form
  foreach ($f in $frames) {
    if ($f.tail) {
      if ($f.horizontal) {
        $x = $xLocationList[$f.col+1] - $f.panel.Size.Width
        $y = $yLocationList[$f.row]
      }
      else {
        $x = $xLocationList[$f.col]
        $y = $yLocationList[$f.row+1] - $f.panel.Size.Height
      }
    }
    else {
      $x = $xLocationList[$f.col]
      $y = $yLocationList[$f.row]
    }

    $f.panel.Location = New-Object System.Drawing.Point($x, $y)
    $form.Controls.Add($f.panel)
  }

  $form.Text = $hash.text
  $form.ClientSize = New-Object System.Drawing.Size(
    ($xLocationList[-1] + $hash.padRight),
    ($yLocationList[-1] + $hash.padBottom)
  )
  $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
  $form.StartPosition = "CenterScreen"

  $form
}



# プルダウンメニューを生成
#function new-comboBox([int] $left, [int] $top, [int] $width, [int] $height) {
#  $cb               = New-Object System.Windows.Forms.ComboBox
#  $cb.Location      = New-Object System.Drawing.Point($left, $top)
#  $cb.Size          = New-Object System.Drawing.Size($width, $height)
#  $cb.DropDownStyle = "DropDownList"
#  $cb
#}
