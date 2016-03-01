
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

  # �t���[��
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

    # ���W���Z�b�g�����ɐ�Ƀp�l���ɒǉ��������闝�R�́A
    # Label�̓p�l���ɒǉ����Ȃ��ƁA�T�C�Y���m�肳��Ȃ����߁A
    foreach ($c in $ctrls) {
      $panel.controls.Add($c)
    }

    # �R���g���[���̍��W���Z�b�g����
    if ($horizontal) {
      $maxHeight = max $ctrls { $_.Size.Height }
      # �R���g���[�������ɕ��ׂ�
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
      # �R���g���[�����c�ɕ��ׂ�
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
