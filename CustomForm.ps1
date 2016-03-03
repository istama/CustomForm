
#
# Windows�t�H�[�����ȒP�ɋL�q���邽�߂̃��C�u����
#

Set-StrictMode -Version Latest

# .NET�̃��C�u�������C���|�[�g
[void][reflection.assembly]::LoadWithPartialName("System.Windows.Forms")

# �N���X��`���i�[���邽�߂̗̈�
$global:__FormClassTable__ = @{}

# �N���X��`
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

  # �N���X��`�����s���Ĕj������
  # �������邱�ƂŃN���X��`�ɍ\���G���[���������ꍇ�A
  # �C���X�^���X�������ł͂Ȃ��N���X��`�̎��_�ŃG���[���o�ł���
  __new__formInstance $hash > $null

  $global:__FormClassTable__[$type] = $hash
}

# �C���X�^���X�������\�b�h�̃L�[���[�h���쐬
function global:Create-Form ([string] $type) {
  $hash = $__FormClassTable__[$type]
  if (! $hash) {
    thorw "$type is undefined"
  }

  __new__formInstance $hash
}

# �N���X��`���폜���邽�߂̃w���p�[�֐�
function Remove-Class ([string] $type) {
  $__FormClassTable__.remove($type)
}

# �N���X��`���L�q���ꂽ�X�N���v�g�u���b�N�����s���A
# ���������o�I�u�W�F�N�g�̃R���N�V������Ԃ��w���p�[�֐���p�ӂ���
function global:__new__formInstance ([hashtable] $hash) {
  #
  # .NET���C�u�����̊ȈՖ�
  #
  $CONTENT_ALIGNMENT = [System.Drawing.ContentAlignment]

  #
  # �w���p�[���\�b�h�̒�`
  #

  # �l���`�F�b�N�������ɓ��Ă͂܂�Ȃ��ꍇ�̓G���[���b�Z�[�W�𓊂���
  function assert ([scriptblock] $require, [string] $msg) {
    if (! (&$require)) { throw $msg }
  }

  # �G���[���b�Z�[�W�𓊂���w���p�[���\�b�h
  function elementSyntax($msg) {
    throw "class element syntax: $msg"
  }

  # �R���N�V�������̍ő�l���擾����
  function max ($array, [scriptblock] $handle) {
    ($array | foreach $handle | Measure-Object -max).Maximum
  }
  # �R���N�V�������̍ő�l���擾����
  function sum ($array, [scriptblock] $handle) {
    ($array | foreach $handle | Measure-Object -sum).Sum
  }

  # �R���g���[����e�R���g���[���ɒǉ�
  function Create-ControlTree {
    param(
      [Parameter(Mandatory=$true)] $parent,
      [Parameter(Mandatory=$true)][scriptblock] $definition
    )
    # ��`���ꂽ�R���g���[���̃I�u�W�F�N�g���擾
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
        # �e�t���[���ɍs�v�f��ǉ�
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

    # �e�s�Ɨ�̒������擾
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

    # �e�s�Ɨ�̊J�n���W���擾
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

    # �e�R���g���[���ɃR���g���[����ǉ�����
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

  # ���x���̃T�C�Y�ƕ\���ʒu���Z�b�g����
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

  # �R���g���[���̃T�C�Y���Z�b�g
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
  # �R���g���[���̒�`
  #

  # �R���g���[���̔z�u���`����I�u�W�F�N�g���쐬
  # �R���g���[���̃��b�p�[�ƂȂ�
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

  # �t���[�����쐬
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

  # �{�^�����쐬
  function button ([string] $text="", [int] $width=-1, [int] $height=-1, [scriptblock] $event) {
    $b      = New-Object System.Windows.Forms.Button
    $b.Text = $text
    Set-SizeToControl $b $width $height
    $b.add_click($event)
    $b
  }

  # ���x���𐶐�
  function label([string] $text="") {
    $l          = New-Object System.Windows.Forms.Label
    $l.Text     = $text
    $l.AutoSize = $true
    $l
  }



  #
  # �֐��{���̊J�n
  #

  # �e�t���[���̃I�u�W�F�N�g���擾
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
      # �e�t���[���ɍs�v�f��ǉ�
      if ($_.col -ne $col) {
        $row = 0
        $col = $_.col
      }
      $_.row = $row++
      $_
    })

  # �e�s�Ɨ�̒������擾
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

  # �e�s�Ɨ�̊J�n���W���擾
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

  # �t�H�[���Ƀt���[����ǉ�����
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



# �v���_�E�����j���[�𐶐�
#function new-comboBox([int] $left, [int] $top, [int] $width, [int] $height) {
#  $cb               = New-Object System.Windows.Forms.ComboBox
#  $cb.Location      = New-Object System.Drawing.Point($left, $top)
#  $cb.Size          = New-Object System.Drawing.Size($width, $height)
#  $cb.DropDownStyle = "DropDownList"
#  $cb
#}
