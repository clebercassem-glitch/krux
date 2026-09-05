Add-Type -AssemblyName System.Drawing

$repoRoot = Split-Path -Parent $PSScriptRoot
$assetsDir = Join-Path $repoRoot "assets"
$outRoot = Join-Path $repoRoot "social-kit\reaproveitados-fortis"
$pngDir = Join-Path $outRoot "png"
$copyDir = Join-Path $outRoot "copy"

New-Item -ItemType Directory -Force -Path $pngDir | Out-Null
New-Item -ItemType Directory -Force -Path $copyDir | Out-Null

$logoPath = Join-Path $assetsDir "logo-approved.png"
$markPath = Join-Path $assetsDir "krux-x-approved.png"
$logo = [System.Drawing.Image]::FromFile($logoPath)
$mark = [System.Drawing.Image]::FromFile($markPath)

function Color-Hex($hex) {
  return [System.Drawing.ColorTranslator]::FromHtml($hex)
}

function Brush($hex, $alpha = 255) {
  $c = Color-Hex $hex
  return New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb($alpha, $c.R, $c.G, $c.B))
}

function Pen-Hex($hex, $width = 1, $alpha = 255) {
  $c = Color-Hex $hex
  return New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb($alpha, $c.R, $c.G, $c.B)), $width
}

function Font-New($name, $size, $style = [System.Drawing.FontStyle]::Regular) {
  try {
    return New-Object System.Drawing.Font($name, $size, $style, [System.Drawing.GraphicsUnit]::Pixel)
  } catch {
    return New-Object System.Drawing.Font("Arial", $size, $style, [System.Drawing.GraphicsUnit]::Pixel)
  }
}

function Rounded-Rect($x, $y, $w, $h, $r) {
  $p = New-Object System.Drawing.Drawing2D.GraphicsPath
  $p.AddArc($x, $y, $r, $r, 180, 90)
  $p.AddArc($x + $w - $r, $y, $r, $r, 270, 90)
  $p.AddArc($x + $w - $r, $y + $h - $r, $r, $r, 0, 90)
  $p.AddArc($x, $y + $h - $r, $r, $r, 90, 90)
  $p.CloseFigure()
  return $p
}

function Draw-WrappedText($g, $text, $font, $brush, $x, $y, $maxWidth, $lineHeight, $maxLines = 8) {
  $words = $text -split " "
  $line = ""
  $lineCount = 0
  foreach ($word in $words) {
    $test = if ($line.Length -eq 0) { $word } else { "$line $word" }
    $size = $g.MeasureString($test, $font)
    if ($size.Width -le $maxWidth) {
      $line = $test
    } else {
      if ($line.Length -gt 0) {
        $g.DrawString($line, $font, $brush, $x, $y)
        $y += $lineHeight
        $lineCount++
      }
      $line = $word
      if ($lineCount -ge $maxLines) { break }
    }
  }
  if ($line.Length -gt 0 -and $lineCount -lt $maxLines) {
    $g.DrawString($line, $font, $brush, $x, $y)
    $y += $lineHeight
  }
  return $y
}

function Draw-GlowLine($g, $x1, $y1, $x2, $y2, $alpha = 190) {
  for ($i = 13; $i -ge 2; $i -= 2) {
    $pen = Pen-Hex "#0066FF" $i ([Math]::Max(8, [int]($alpha / ($i * 1.2))))
    $g.DrawLine($pen, $x1, $y1, $x2, $y2)
    $pen.Dispose()
  }
  $core = Pen-Hex "#00AAFF" 2 230
  $g.DrawLine($core, $x1, $y1, $x2, $y2)
  $core.Dispose()
}

function Draw-Background($g, $w, $h, $phase) {
  $rect = [System.Drawing.Rectangle]::new(0, 0, $w, $h)
  $bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, (Color-Hex "#080D10"), (Color-Hex "#061A32"), 28)
  $g.FillRectangle($bg, $rect)
  $bg.Dispose()

  $gridPen = Pen-Hex "#FFFFFF" 1 20
  for ($x = 0; $x -le $w; $x += 90) { $g.DrawLine($gridPen, $x, 0, $x, $h) }
  for ($y = 0; $y -le $h; $y += 90) { $g.DrawLine($gridPen, 0, $y, $w, $y) }
  $gridPen.Dispose()

  $poly = [System.Drawing.Point[]]@(
    [System.Drawing.Point]::new([int]($w * .64), 0),
    [System.Drawing.Point]::new($w, 0),
    [System.Drawing.Point]::new($w, $h),
    [System.Drawing.Point]::new([int]($w * .82), $h)
  )
  $polyBrush = Brush "#071E3B" 215
  $g.FillPolygon($polyBrush, $poly)
  $polyBrush.Dispose()

  $edge = Pen-Hex "#C0C2C8" 1 58
  $g.DrawLine($edge, [int]($w * .64), 0, [int]($w * .82), $h)
  $edge.Dispose()

  Draw-GlowLine $g -30 (780 + ($phase % 3) * 34) ($w + 40) (620 + ($phase % 4) * 24) 150
  Draw-GlowLine $g 670 180 1070 (60 + ($phase % 3) * 80) 88

  $circuit = Pen-Hex "#0066FF" 2 78
  for ($i = 0; $i -lt 8; $i++) {
    $y = 145 + ($i * 46)
    $x = 815 + (($i % 2) * 35)
    $g.DrawLine($circuit, $x, $y, 1040, $y - 28)
    $g.DrawEllipse($circuit, 1038, $y - 32, 8, 8)
  }
  $circuit.Dispose()
}

function Draw-ServiceIcon($g, $type, $x, $y) {
  $blue = Brush "#008CFF"
  $silverPen = Pen-Hex "#FFFFFF" 8 220
  $bluePen = Pen-Hex "#008CFF" 9 230
  if ($type -eq "fan") {
    $g.DrawEllipse($silverPen, $x, $y, 118, 118)
    $g.DrawLine($bluePen, $x + 59, $y + 22, $x + 59, $y + 96)
    $g.DrawLine($bluePen, $x + 22, $y + 59, $x + 96, $y + 59)
  } elseif ($type -eq "monitor") {
    $g.DrawRectangle($silverPen, $x, $y, 130, 88)
    $g.DrawLine($bluePen, $x + 28, $y + 112, $x + 102, $y + 112)
    $g.DrawLine($bluePen, $x + 65, $y + 88, $x + 65, $y + 112)
  } elseif ($type -eq "database") {
    $g.DrawEllipse($silverPen, $x, $y, 132, 36)
    $g.DrawLine($silverPen, $x, $y + 18, $x, $y + 96)
    $g.DrawLine($silverPen, $x + 132, $y + 18, $x + 132, $y + 96)
    $g.DrawEllipse($bluePen, $x, $y + 80, 132, 36)
  } elseif ($type -eq "network") {
    $g.DrawEllipse($silverPen, $x + 48, $y, 38, 38)
    $g.DrawEllipse($silverPen, $x, $y + 86, 38, 38)
    $g.DrawEllipse($silverPen, $x + 96, $y + 86, 38, 38)
    $g.DrawLine($bluePen, $x + 66, $y + 38, $x + 18, $y + 86)
    $g.DrawLine($bluePen, $x + 66, $y + 38, $x + 114, $y + 86)
  } elseif ($type -eq "shield") {
    $pts = [System.Drawing.Point[]]@(
      [System.Drawing.Point]::new($x + 66, $y),
      [System.Drawing.Point]::new($x + 126, $y + 28),
      [System.Drawing.Point]::new($x + 112, $y + 98),
      [System.Drawing.Point]::new($x + 66, $y + 136),
      [System.Drawing.Point]::new($x + 20, $y + 98),
      [System.Drawing.Point]::new($x + 6, $y + 28)
    )
    $g.DrawPolygon($silverPen, $pts)
    $g.DrawLine($bluePen, $x + 36, $y + 70, $x + 58, $y + 92)
    $g.DrawLine($bluePen, $x + 58, $y + 92, $x + 102, $y + 46)
  } else {
    $g.DrawLine($silverPen, $x, $y + 92, $x + 92, $y)
    $g.DrawLine($silverPen, $x + 42, $y + 2, $x + 134, $y + 94)
    $g.DrawLine($bluePen, $x + 40, $y + 48, $x + 94, $y + 48)
    $g.DrawLine($bluePen, $x + 67, $y + 21, $x + 67, $y + 75)
  }
  $blue.Dispose()
  $silverPen.Dispose()
  $bluePen.Dispose()
}

function Draw-Post($item) {
  $w = 1080
  $h = 1080
  $bmp = New-Object System.Drawing.Bitmap($w, $h)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

  Draw-Background $g $w $h $item.Index

  $logoW = 385
  $logoH = [int]($logo.Height * ($logoW / $logo.Width))
  $g.DrawImage($logo, 72, 64, $logoW, $logoH)

  $seriesFont = Font-New "Segoe UI" 21 ([System.Drawing.FontStyle]::Bold)
  $idxFont = Font-New "Bahnschrift" 30 ([System.Drawing.FontStyle]::Bold)
  $blue = Brush "#00AAFF"
  $muted = Brush "#AEB7C4"
  $white = Brush "#FFFFFF"
  $silver = Brush "#D8DBE0"

  $g.DrawString("KRUX TECNOLOGIA", $seriesFont, $blue, 73, 188)
  $g.DrawString(("{0:00}" -f $item.Index), $idxFont, $blue, 958, 74)

  $panelPath = Rounded-Rect 700 250 292 292 32
  $panelBrush = Brush "#0B0D10" 230
  $g.FillPath($panelBrush, $panelPath)
  $panelBorder = Pen-Hex "#C0C2C8" 2 80
  $g.DrawPath($panelBorder, $panelPath)
  $g.DrawImage($mark, 732, 282, 228, 228)
  $panelPath.Dispose()
  $panelBrush.Dispose()
  $panelBorder.Dispose()

  Draw-ServiceIcon $g $item.Icon 778 642

  $kickerFont = Font-New "Segoe UI" 29 ([System.Drawing.FontStyle]::Bold)
  $titleSize = if ($item.Title.Length -gt 34) { 62 } else { 70 }
  $titleFont = Font-New "Arial Black" $titleSize ([System.Drawing.FontStyle]::Bold)
  $bodyFont = Font-New "Segoe UI" 34 ([System.Drawing.FontStyle]::Regular)
  $ctaFont = Font-New "Segoe UI" 25 ([System.Drawing.FontStyle]::Bold)
  $microFont = Font-New "Segoe UI" 20 ([System.Drawing.FontStyle]::Regular)

  $g.DrawString($item.Kicker.ToUpperInvariant(), $kickerFont, $blue, 72, 260)
  [void](Draw-WrappedText $g $item.Title $titleFont $white 72 326 650 76 4)
  [void](Draw-WrappedText $g $item.Body $bodyFont $silver 76 620 650 45 5)

  $bar = Rounded-Rect 72 914 936 86 14
  $barBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    [System.Drawing.Rectangle]::new(72, 914, 936, 86),
    (Color-Hex "#0066FF"),
    (Color-Hex "#071F3D"),
    0
  )
  $g.FillPath($barBrush, $bar)
  $barBorder = Pen-Hex "#00AAFF" 2 190
  $g.DrawPath($barBorder, $bar)
  $g.DrawString($item.CTA, $ctaFont, $white, 110, 942)
  $g.DrawString($item.Tag, $microFont, $muted, 754, 845)
  $bar.Dispose()
  $barBrush.Dispose()
  $barBorder.Dispose()

  $seriesFont.Dispose()
  $idxFont.Dispose()
  $blue.Dispose()
  $muted.Dispose()
  $white.Dispose()
  $silver.Dispose()
  $kickerFont.Dispose()
  $titleFont.Dispose()
  $bodyFont.Dispose()
  $ctaFont.Dispose()
  $microFont.Dispose()
  $g.Dispose()

  $file = Join-Path $pngDir ("fortis-recriado-krux-{0:00}.png" -f $item.Index)
  $bmp.Save($file, [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
}

$posts = @(
  @{
    Index = 1
    Icon = "fan"
    Kicker = "Manutenção preventiva"
    Title = "Limpeza técnica evita parada"
    Body = "Poeira, aquecimento e travamentos precisam de prevenção, não improviso. Manutenção técnica reduz paradas."
    CTA = "Agende um checkup KRUX"
    Tag = "Desktop | Notebook | Empresa"
  },
  @{
    Index = 2
    Icon = "monitor"
    Kicker = "Checkup"
    Title = "Antes de formatar, diagnostique"
    Body = "Computador lento pode ser disco, memória, vírus, atualização, rede ou sistema. Primeiro vem análise técnica."
    CTA = "Diagnóstico antes de apagar tudo"
    Tag = "Suporte consultivo"
  },
  @{
    Index = 3
    Icon = "shield"
    Kicker = "Segurança"
    Title = "Backup sem teste não protege"
    Body = "A rotina só é confiável quando restaura, registra falhas e tem responsabilidade clara."
    CTA = "Proteja arquivos e operação"
    Tag = "Continuidade"
  },
  @{
    Index = 4
    Icon = "network"
    Kicker = "Infraestrutura"
    Title = "Rede instável custa produtividade"
    Body = "Wi-Fi, cabeamento, servidor e estações precisam conversar bem para a empresa não parar."
    CTA = "Organize sua infraestrutura"
    Tag = "Rede | Windows Server"
  },
  @{
    Index = 5
    Icon = "x"
    Kicker = "Suporte N3"
    Title = "Problema recorrente pede causa raiz"
    Body = "O atendimento KRUX investiga origem, impacto e prevenção para o erro não virar rotina."
    CTA = "Resolva com critério técnico"
    Tag = "+20 anos em TI"
  },
  @{
    Index = 6
    Icon = "database"
    Kicker = "SQL Server"
    Title = "Banco de dados não aceita chute"
    Body = "Script, consulta, ajuste e correção precisam ser feitos com método quando afetam venda e faturamento."
    CTA = "Apoio técnico em SQL Server"
    Tag = "Dados críticos"
  },
  @{
    Index = 7
    Icon = "monitor"
    Kicker = "ERP"
    Title = "Sistema bom exige implantação boa"
    Body = "Treinamento, processo, parametrização e suporte definem se o ERP ajuda ou vira gargalo."
    CTA = "Implantação com visão prática"
    Tag = "ERP | Processos"
  },
  @{
    Index = 8
    Icon = "network"
    Kicker = "Integrações"
    Title = "API falhou? Ache o ponto certo"
    Body = "Logs, retornos, WebServices e sistemas conectados precisam de leitura técnica e documentação."
    CTA = "Conecte sistemas com clareza"
    Tag = "APIs | WebServices"
  }
)

foreach ($post in $posts) {
  Draw-Post $post
}

$caption = @'
# Posts antigos da Fortis recriados para KRUX

Pacote criado para reaproveitar apenas temas que fazem sentido para a nova fase da KRUX Tecnologia. A linha visual segue a identidade nova: preto/grafite, prata, branco, azul eletrico e o X cruzado pela cruz azul.

## Temas reaproveitados

1. Limpeza e manutencao preventiva de computadores.
2. Checkup antes de formatacao.
3. Suporte tecnico consultivo para empresas e profissionais.
4. Infraestrutura, rede e ambientes Windows.
5. Backup, seguranca e continuidade.
6. SQL Server, ERP e integracoes.

## Temas descartados

- Conteudos fora do foco atual da KRUX, como Meta Quest, assuntos aleatorios ou posts que nao conversam com TI empresarial.
- Assistencia de celular como oferta principal. Esse tema so deve aparecer quando for suporte a mobilidade corporativa, aplicativo de trabalho ou operacao do cliente.

## Ordem sugerida

1. `fortis-recriado-krux-01.png` - Limpeza tecnica evita parada.
2. `fortis-recriado-krux-02.png` - Antes de formatar, diagnostique.
3. `fortis-recriado-krux-05.png` - Problema recorrente pede causa raiz.
4. `fortis-recriado-krux-04.png` - Rede instavel custa produtividade.
5. `fortis-recriado-krux-03.png` - Backup sem teste nao protege.
6. `fortis-recriado-krux-07.png` - Sistema bom exige implantacao boa.
7. `fortis-recriado-krux-06.png` - Banco de dados nao aceita chute.
8. `fortis-recriado-krux-08.png` - API falhou? Ache o ponto certo.

## Legendas

### 01 - Limpeza tecnica evita parada

Computador travando nem sempre precisa ser trocado.

Poeira, aquecimento e manutencao atrasada podem derrubar desempenho e criar paradas desnecessarias. A KRUX faz uma avaliacao tecnica para manter a rotina funcionando com mais seguranca.

WhatsApp: (91) 93300-5646

#KruxTecnologia #SuporteTecnico #ManutencaoPreventiva #TIParaEmpresas #BelemPA

### 02 - Antes de formatar, diagnostique

Formatar sem diagnostico pode apagar tempo, configuracao e historico sem resolver a causa.

Computador lento pode envolver disco, memoria, virus, atualizacao, rede ou sistema. Primeiro a KRUX analisa. Depois recomenda o caminho certo.

WhatsApp: (91) 93300-5646

#KruxTecnologia #CheckupTecnico #SuporteConsultivo #TecnologiaBelem #BelemPA

### 03 - Backup sem teste nao protege

Backup bom nao e o que apenas existe. E o que restaura quando a empresa precisa.

A KRUX ajuda a revisar rotina, nuvem, pastas criticas e responsabilidade para reduzir risco de perda de dados.

WhatsApp: (91) 93300-5646

#KruxTecnologia #Backup #SegurancaDaInformacao #TIParaEmpresas #BelemPA

### 04 - Rede instavel custa produtividade

Internet caindo, Wi-Fi fraco, servidor lento e maquina sem acesso viram perda de tempo todos os dias.

A KRUX avalia infraestrutura, rede, Windows Server e pontos de falha para sua operacao rodar melhor.

WhatsApp: (91) 93300-5646

#KruxTecnologia #InfraestruturaTI #Redes #WindowsServer #BelemPA

### 05 - Problema recorrente pede causa raiz

Quando o mesmo erro volta toda semana, o problema nao foi resolvido de verdade.

O suporte N3 da KRUX olha origem, impacto e prevencao para tirar a empresa do ciclo de chamado repetido.

WhatsApp: (91) 93300-5646

#KruxTecnologia #SuporteN3 #AmbientesCriticos #TIConsultiva #BelemPA

### 06 - Banco de dados nao aceita chute

SQL Server sustenta venda, atendimento, estoque, faturamento e decisao.

Consultas, scripts e ajustes precisam ser feitos com cuidado, principalmente quando o ambiente esta em producao.

WhatsApp: (91) 93300-5646

#KruxTecnologia #SQLServer #BancoDeDados #Sistemas #BelemPA

### 07 - Sistema bom exige implantacao boa

ERP nao e so instalar e sair usando.

Parametrizacao, treinamento, processo e suporte definem se o sistema vira produtividade ou gargalo. A KRUX atua nessa ponte entre tecnologia e operacao.

WhatsApp: (91) 93300-5646

#KruxTecnologia #ERP #ImplantacaoDeSistemas #Processos #BelemPA

### 08 - API falhou? Ache o ponto certo

Quando uma integracao para, o problema pode estar no retorno, no token, no endpoint, no servidor, na regra de negocio ou no sistema de origem.

A KRUX analisa logs, WebServices e fluxos para encontrar o ponto de ruptura.

WhatsApp: (91) 93300-5646

#KruxTecnologia #APIs #WebServices #Integracoes #BelemPA
'@

$captionPath = Join-Path $copyDir "legendas-posts-fortis-recriados.md"
[System.IO.File]::WriteAllText($captionPath, $caption, [System.Text.UTF8Encoding]::new($false))

$logo.Dispose()
$mark.Dispose()

Write-Host "Posts recriados em $pngDir"
Write-Host "Legendas em $captionPath"
