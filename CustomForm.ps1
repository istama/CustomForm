
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

  # コントロールを親コントロールに追加
  function Create-ControlTree {
    param(
      [Parameter(Mandatory=$true)] $parent,
      [Parameter(Mandatory=$true)][scriptblock] $definition
    )
    # 定義されたコントロールのオブジェクトを取得
    $ctrls = @(
      &$definition |
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

    foreach ($c in $ctrls) {
      $parent.obj.Controls.Add($c.obj)
    }

    # 各行と列の長さを取得
    $widthList = @()
    $heightList = @()
    foreach ($c in $ctrls) {
      $w = $c.marginLeft + $c.obj.Size.Width + $c.marginRight
      if ($c.col -ge $widthList.count) {
        $widthList += $w
      }
      elseif ($w -gt $widthList[$c.col]) {
        $widthList[$c.col] = $w
      }

      $h = $c.marginTop + $c.obj.Size.Height + $c.marginBottom
      if ($c.row -ge $heightList.count) {
        $heightList += $h
      }
      elseif ($h -gt $heightList[$c.row]) {
        $heightList[$c.row] = $h
      }
    }

    # 各行と列の開始座標を取得
    $xLocationList = @(
      $parent.padLeft
      if ($widthList.count -gt 0) {
        foreach ($i in 0..($widthList.count-1)) {
          $parent.padLeft + (sum $widthList[0..$i] { $_ })
        }
      })
    $yLocationList = @(
      $parent.padTop
      if ($heightList.count -gt 0) {
        foreach ($i in 0..($heightList.count-1)) {
          $parent.padTop + (sum $heightList[0..$i] { $_ })
        }
      })

    # 親コントロールにコントロールを追加する
    switch ($ctrls | foreach { $_.align }) {
      TopLeft {
        $x = $xLocationList[$_.col] + $_.marginLeft
        $y = $yLocationList[$_.row] + $_.marginTop
        $_.obj.Location = New-Object System.Drawing.Point($x, $y)
        $parent.obj.Controls.Add($_.obj)
        continue
      }
      TopCenter {
        $x = $xLocationList[$_.col] + ($xLocationList[$_.col+1] - $_.obj.Size.Width - $xLocationList[$_.col]) / 2
        $y = $yLocationList[$_.row] + $_.marginTop
        $_.obj.Location = New-Object System.Drawing.Point($x, $y)
        $parent.obj.Controls.Add($_.obj)
        continue
      }
      TopRight {
        $x = $xLocationList[$_.col+1] - $_.obj.Size.Width - $_.marginRight
        $y = $yLocationList[$_.row] + $_.marginTop
        $_.obj.Location = New-Object System.Drawing.Point($x, $y)
        $parent.obj.Controls.Add($_.obj)
        continue
      }
      MiddleLeft {
        $x = $xLocationList[$_.col] + $_.marginLeft
        $y = $yLocationList[$_.row] + ($xLocationList[$_.row+1] - $_.obj.Size.Height - $xLocationList[$_.row]) / 2
        $_.obj.Location = New-Object System.Drawing.Point($x, $y)
        $parent.obj.Controls.Add($_.obj)
        continue
      }
      MiddleCenter {
        $x = $xLocationList[$_.col] + ($xLocationList[$_.col+1] - $_.obj.Size.Width - $xLocationList[$_.col]) / 2
        $y = $yLocationList[$_.row] + ($xLocationList[$_.row+1] - $_.obj.Size.Height - $xLocationList[$_.row]) / 2
        $_.obj.Location = New-Object System.Drawing.Point($x, $y)
        $parent.obj.Controls.Add($_.obj)
        continue
      }
      MiddleRight {
        $x = $xLocationList[$_.col+1] - $_.obj.Size.Width - $_.marginRight
        $y = $yLocationList[$_.row] + ($xLocationList[$_.row+1] - $_.obj.Size.Height - $xLocationList[$_.row]) / 2
        $_.obj.Location = New-Object System.Drawing.Point($x, $y)
        $parent.obj.Controls.Add($_.obj)
        continue
      }
      BottomLeft {
        $x = $xLocationList[$_.col] + $_.marginLeft
        $y = $yLocationList[$_.row+1] - $_.obj.Size.Height - $_.marginBottom
        $_.obj.Location = New-Object System.Drawing.Point($x, $y)
        $parent.obj.Controls.Add($_.obj)
        continue
      }
      BottomCenter {
        $x = $xLocationList[$_.col] + ($xLocationList[$_.col+1] - $_.obj.Size.Width - $xLocationList[$_.col]) / 2
        $y = $yLocationList[$_.row+1] - $_.obj.Size.Height - $_.marginBottom
        $_.obj.Location = New-Object System.Drawing.Point($x, $y)
        $parent.obj.Controls.Add($_.obj)
        continue
      }
      BottomRight {
        $x = $xLocationList[$_.col+1] - $_.obj.Size.Width - $_.marginRight
        $y = $yLocationList[$_.row+1] - $_.obj.Size.Height - $_.marginBottom
        $_.obj.Location = New-Object System.Drawing.Point($x, $y)
        $parent.obj.Controls.Add($_.obj)
        continue
      }
    }

    $parent.obj.ClientSize = New-Object System.Drawing.Size(
      ($xLocationList[-1] + $parent.padRight),
      ($yLocationList[-1] + $parent.padBottom)
    )
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

  # コントロールの配置を定義するオブジェクトを作成
  # コントロールのラッパーとなる
  function control {
    param(
      [int] $col=0,
      [int] $marginTop=0,
      [int] $marginBottom=0,
      [int] $marginLeft=0,
      [int] $marginRight=0,
      [string] $align="TopLeft",
      [Parameter(Mandatory=$true)] $control=$null
    )
    @{
      obj          = $control
      col          = $col
      marginLeft   = $marginLeft
      marginRight  = $marginRight
      marginTop    = $marginTop
      marginBottom = $marginBottom
      align        = $align
    }
  }

  # フレームを作成
  function frame {
    param(
      [int] $padTop=10,
      [int] $padBottom=10,
      [int] $padLeft=10,
      [int] $padRight=10,
      [Parameter(Mandatory=$true)]
      [scriptblock] $definition
    )
    $frame = @{
      obj       = New-Object System.Windows.Forms.Panel
      padTop    = $padTop
      padBottom = $padBottom
      padLeft   = $padLeft
      padRight  = $padRight
    }

    Create-ControlTree $frame $definition
  }

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
