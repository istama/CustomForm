
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

  $param = @{
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
  #__new__formInstance $param > $null

  $global:__FormClassTable__[$type] = $param
}

# �C���X�^���X�������\�b�h�̃L�[���[�h���쐬
function global:Create-Form ([string] $type) {
  $param = $__FormClassTable__[$type]
  if (! $param) {
    thorw "$type is undefined"
  }

  __new__formInstance $param
}

# �N���X��`���폜���邽�߂̃w���p�[�֐�
function Remove-Class ([string] $type) {
  $__FormClassTable__.remove($type)
}

# �N���X��`���L�q���ꂽ�X�N���v�g�u���b�N�����s���A
# ���������o�I�u�W�F�N�g�̃R���N�V������Ԃ��w���p�[�֐���p�ӂ���
function global:__new__formInstance ([hashtable] $param) {
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

    $sbHeadLoc   = { param($idx) $this[$idx] }
    $sbCenterLoc = { param($idx, $size) $this[$idx] + ($this[$idx+1] - $size - $this[$idx]) / 2 }
    $sbTailLoc   = { param($idx, $size) $this[$idx+1] - $size}

    $xLocationList = Add-Member -in $xLocationList -member scriptMethod -name GetHeadLocation -value $sbHeadLoc -passthru
    Add-Member -in $xLocationList -member scriptMethod -n GetCenterLocation -value $sbCenterLoc
    Add-Member -in $xLocationList -member scriptMethod -n GetTailLocation -value $sbTailLoc
    $yLocationList = Add-Member -passthru -in $yLocationList scriptMethod GetHeadLocation $sbHeadLoc
    Add-Member -in $yLocationList scriptMethod GetCenterLocation $sbCenterLoc
    Add-Member -in $yLocationList scriptMethod GetTailLocation $sbTailLoc

    # �e�R���g���[���ɃR���g���[����ǉ�����
    switch -wildcard -regex ($ctrls) {
      {$_.align -match '^Top'}    { $y = $yLocationList.GetHeadLocation($_.row) + $_.marginTop }
      {$_.align -match "^Middle"} { $y = $yLocationList.GetCenterLocation($_.row, $_.obj.Size.Height) }
      {$_.align -match "^Bottom"} { $y = $yLocationList.GetTailLocation($_.row, $_.obj.Size.Height) - $_.marginBottom }
      {$_.align -match "Left$"}   { $x = $xLocationList.GetHeadLocation($_.col) + $_.marginLeft }
      {$_.align -match "Center$"} { $x = $xLocationList.GetCenterLocation($_.col, $_.obj.Size.Width) }
      {$_.align -match "Right$"}  { $x = $xLocationList.GetTailLocation($_.col, $_.obj.Size.Width) - $_.marginRight }
      { $true } { $_.obj.Location = New-Object System.Drawing.Point($x, $y) }
    }

    $parent.obj.ClientSize = New-Object System.Drawing.Size(
      ($xLocationList[-1] + $parent.padRight),
      ($yLocationList[-1] + $parent.padBottom)
    )

    write-host "frameSize: w: " $parent.PadLeft " " $xLocationList[-1] " " $parent.PadRight
    write-host "frameSize: h: " $parent.PadTop " " $yLocationList[-1] " " $parent.PadBottom

    $parent.obj
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
  function frame {
    param(
      [Parameter(Mandatory=$true, Position=1)] $control=$null,
      [int] $col=0,
      [int] $marginTop=0,
      [int] $marginBottom=0,
      [int] $marginLeft=0,
      [int] $marginRight=0,
      [string] $align="TopLeft"
    )
    assert { $col -ge 0 } "-col must be more than 0."

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

  # �p�l�����쐬
  function panel {
    param(
      [Parameter(Mandatory=$true, Position=1)]
      [scriptblock] $definition,
      [int] $padTop=10,
      [int] $padBottom=10,
      [int] $padLeft=10,
      [int] $padRight=10
    )
    $panel = @{
      obj       = New-Object System.Windows.Forms.Panel
      padTop    = $padTop
      padBottom = $padBottom
      padLeft   = $padLeft
      padRight  = $padRight
    }

    Create-ControlTree $panel $definition
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

  $parent = @{
    obj       = New-Object System.Windows.Forms.Form
    padTop    = $param.padTop
    padBottom = $param.padBottom
    padLeft   = $param.padLeft
    padRight  = $param.padRight
  }

  $form = Create-ControlTree $parent $param.definition

  $form.Text = $param.text
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
