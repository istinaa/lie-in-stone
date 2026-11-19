# 《假勇者》美术素材清单（按优先级）+ 生图 Prompt

> 整理日期：2026-11-15
> 每一项都附有一段**可以直接复制去生图**的英文 Prompt（英文对大多数生图模型更稳定）。
> 规格、文件放置方式、已有素材的情况见 `docs/美术需求清单.md`。

> **进度（2026-11-15）**：P0 全部完成并已接入游戏；P1 完成 8 张 CG（除标题主视觉 P1-9，标题画面暂用圣剑择主 CG）；P2 完成酒馆老板娘；P3 完成国王、间谍重绘。

---

## 使用说明

### 优先级
| 级别 | 含义 | 数量 |
|---|---|---|
| **P0** | 每局游戏都会反复看到，缺了最影响观感 | 7 |
| **P1** | 关键剧情和结局（过场暂时不显示 CG，可以先画好备用） | 9 |
| **P2** | 补全世界：次要场景、次要 CG、关键道具 | 19 |
| **P3** | 锦上添花：扩展角色、隐藏结局、图标、UI | 30 |

**已完成、不在本清单里的**：米娅、莱恩哈特、奥斯瓦德、诺娃、大祭司（`主教2.png`）、候选勇者的立绘。
**两张教堂图**以后不作为正殿使用，神殿偏厅也会重绘，所以都列在清单里。

### Prompt 的写法
- 每段 Prompt 都已包含完整的风格描述，**单独复制一段就能用**。
- 风格基准是已有立绘：*semi-realistic anime painterly illustration with a subtle pixel-art texture*。生成后如果风格偏了，可以把一张已有立绘作为**参考图 / 风格参考**一起提交。
- **立绘**：多数模型不能直接输出透明背景，所以 Prompt 里要求纯色背景，生成后再抠图。
- **场景背景**：必须完全不透明、不带人物。地点背景会被右下角的人物面板（约占画面右下 1/2 宽 × 3/5 高）挡住，所以 Prompt 里要求**主体放在画面左侧和上方**。
- **画面里的文字**：生图模型写不好中文，公告、书页等一律要求 *illegible script*（看不清的文字），真正的文字以后用程序或后期加上。
- 如果工具支持负面提示词，统一使用：
  `text, watermark, signature, logo, extra fingers, deformed hands, blurry, lowres, photorealistic, 3d render, chibi`

### 角色外观基准（CG 里出现时保持一致）
| 角色 | 外观关键词 |
|---|---|
| 主角 | young man about 20, lean build, messy straw-blond hair, tired grey eyes, oversized white-and-gold ceremonial tunic with a blue sash, sleeves rolled up, plain sword at his hip |
| 米娅 | 15-year-old girl, wavy shoulder-length brown hair, pale sage-green ribbon headband, cream and sage-green apprentice mage robe, holding a leather-bound tome |
| 莱恩哈特 | middle-aged knight, short dark-grey hair, scar across his cheek, dark navy plate armor and navy cape |
| 奥斯瓦德 | elderly scholar, swept grey hair, grey beard, round wire glasses, dark green hooded robe, holding an old book |
| 诺娃 | young woman in her twenties, short black hair, red scarf, dark grey leather coat with belts and pouches, daggers |
| 大祭司 | elderly high priest, swept-back silver hair, thin cold smile, white and gold vestments with purple trim, gold-embroidered stole |
| 国王 | portly older king, grey beard, gold crown, crimson and gold robes with fur trim |
| 神殿徽记 | a golden sun disc pierced by a downward-pointing sword（建议统一用这个，出现在祭司服、公告、装置上） |

---

## P0 —— 每局都会看到

### P0-1　主角立绘
- 文件：`assets/portraits/hero.png`，2:3，1248×1872，透明背景
- 说明：20 岁左右的男生，神殿后厨的杂役，被临时套上不合身的勇者礼服。**不能像天选之人**，要和候选勇者（棕发冒险者）拉开差别。

```
Half-body character portrait (head to mid-thigh), 3/4 view, standing, vertical 2:3 composition, head in the upper quarter of the frame. A young man about 20 years old, lean and slightly underfed build, messy straw-blond hair, tired grey eyes, a nervous but stubborn expression, calloused hands from kitchen work. He wears an oversized white-and-gold ceremonial hero tunic that clearly does not fit him: shoulders too wide, sleeves rolled up, a blue sash tied crookedly, worn brown kitchen boots. A plain old sword in a simple scabbard hangs at his hip; one hand rests awkwardly on its hilt. He looks like an ordinary servant dressed up as a hero, not a chosen one. Semi-realistic anime painterly illustration with a subtle pixel-art texture, muted warm medieval fantasy palette, soft dramatic rim lighting, detailed fabric folds. Plain flat light-grey background for easy background removal, no text.
```

### P0-2　大神殿·正殿（地点背景）
- 文件：`assets/backgrounds/temple.png`，16:9，2048×1152
- 说明：王国最高神殿，白石金顶，宏伟明亮，和残破的教堂图完全不同。圣剑插在中央的剑座上。

```
Wide 16:9 interior background of a grand royal cathedral in a medieval fantasy kingdom. Majestic nave of polished white marble with towering columns capped in gold, a high golden domed ceiling with sun motifs, tall stained-glass windows casting warm colored light. On the left third of the image, at the end of a long red carpet, an ornate stone altar-pedestal holds an ancient sword thrust point-down into it; above the altar hangs a golden emblem of a sun disc pierced by a downward sword. Rows of white benches, golden candelabras, banners with the sun-and-sword sigil. Pristine, solemn, awe-inspiring and slightly cold. Main focus on the left and upper part of the frame; the lower-right area is calm floor space. No people. Semi-realistic anime painterly illustration with a subtle pixel-art texture, detailed environment art, game background, fully opaque, no text.
```

### P0-3　骑士训练场（地点背景）
- 文件：`assets/backgrounds/training.png`，16:9

```
Wide 16:9 outdoor background of a knights' training ground in a medieval fantasy capital. Packed sand arena surrounded by a wooden fence, straw training dummies and thick wooden practice posts, weapon racks with swords, spears and shields, a stone barracks with a navy-blue banner bearing a knightly crest, castle walls and towers in the distance under a clear afternoon sky. Footprints and scuff marks in the sand, a water trough, a sense of discipline and hard work. Main focus on the left and upper part of the frame; the lower-right area is open sand. No people. Semi-realistic anime painterly illustration with a subtle pixel-art texture, warm muted palette, detailed environment art, game background, fully opaque, no text.
```

### P0-4　王立图书馆（地点背景）

```
Wide 16:9 interior background of a royal library inside a tall blue-roofed tower in a medieval fantasy kingdom. Towering curved wooden bookshelves packed with ancient tomes, a spiral staircase winding upward, ladders on rails, a large oak reading desk on the left covered with open books, scrolls, an astrolabe and a star chart, a candle and inkwell. Dusty golden light falls through tall arched windows, floating dust motes. Quiet, scholarly, mysterious. Main focus on the left and upper part of the frame; the lower-right area is calm wooden floor. No people. Semi-realistic anime painterly illustration with a subtle pixel-art texture, warm muted palette, detailed environment art, game background, fully opaque, no text.
```

### P0-5　金麦酒馆（地点背景）

```
Wide 16:9 interior background of a lively medieval fantasy tavern called the Golden Wheat. Warm amber lamplight, a long wooden bar counter on the left with barrels, mugs and bottles, bundles of dried wheat hanging from the rafters, a stone fireplace, crowded long tables with empty tankards, a notice board covered with pinned papers. Cozy, noisy-looking, a place where rumors spread. Main focus on the left and upper part of the frame; the lower-right area is a calm wooden floor. No people. Semi-realistic anime painterly illustration with a subtle pixel-art texture, warm muted palette, detailed environment art, game background, fully opaque, no text.
```

### P0-6　下城小巷（地点背景）

```
Wide 16:9 outdoor background of a narrow slum alley in the lower district of a medieval fantasy capital at dusk. Crooked leaning houses with patched roofs, laundry lines strung between windows, puddles on broken cobblestones, a dim hanging lantern, crates and barrels, a rusted iron grate leading down into the sewers on the left side, a faint thieves' mark scratched on a wall. Damp, shadowy, secretive but not horrific. Main focus on the left and upper part of the frame; the lower-right area is calm cobblestone ground. No people. Semi-realistic anime painterly illustration with a subtle pixel-art texture, muted cool palette with warm lantern accents, detailed environment art, game background, fully opaque, no text.
```

### P0-7　王都地图
- 文件：`assets/tiles/town.png`，16:9（游戏按 1280×720 显示）
- 说明：5 个地点的位置要和下面的布局一致（换图后我来重新对齐点击区域）。画面最上方约 8% 会被状态栏挡住。

```
Top-down three-quarter view illustrated map of a small medieval fantasy royal capital, 16:9, game world-map style. Layout: at the top center, a grand white-stone cathedral with a golden dome; at the upper left, a knights' training ground with a sand arena, wooden posts and a navy banner; at the right, a tall blue-roofed library tower; at the lower left, a cozy tavern with a red roof and wheat decorations; at the lower right, a cramped slum district with crooked houses. Dirt roads connect all five places through a central plaza, green grass, scattered trees, a few small houses. Keep the top 8 percent of the image as plain sky or treetops. Each of the five places should be clearly separated and readable. Daytime. Semi-realistic anime painterly illustration with a subtle pixel-art texture, warm muted palette, fully opaque, no text, no labels.
```

---

## P1 —— 关键剧情与结局 CG（16:9，1920×1080）

### P1-1　圣剑择主（第 1 天开场）

```
Cinematic 16:9 illustration. Inside a grand white-marble cathedral with a golden dome, a young man about 20 with messy straw-blond hair in an oversized white-and-gold ceremonial tunic grips the hilt of an ancient sword set in a stone altar; brilliant golden light bursts upward from the altar base, flooding the hall. Thousands of townspeople kneel in awe across the nave and out through the open doors into the plaza. In the front row, a 15-year-old girl with wavy brown hair and a sage-green ribbon headband, hugging a leather tome, cries with joy. Behind the altar, an elderly silver-haired high priest in white and gold vestments watches with a faint cold smile. The young man's face shows no joy at all, only blank confusion. Semi-realistic anime painterly illustration with a subtle pixel-art texture, dramatic god-ray lighting, muted warm palette, no text.
```

### P1-2　骑士团的公开考验（第 3 天）

```
Cinematic 16:9 illustration of a knights' training ground packed with armored knights and curious townspeople forming a circle. In the center stands a thick oak practice post wrapped in iron bands. A middle-aged knight with short dark-grey hair, a scar across his cheek, dark navy plate armor and a navy cape stands with arms crossed, staring challengingly. Facing the post, seen from behind and slightly to the side, a lean young man with messy straw-blond hair in an oversized white-and-gold ceremonial tunic holds a plain sword, his grip tense. Afternoon sun, dust in the air, heavy silence before the strike. Semi-realistic anime painterly illustration with a subtle pixel-art texture, muted warm palette, no text.
```

### P1-3　夜潜正殿：发现魔导装置

```
Cinematic 16:9 night illustration inside a dark grand cathedral, lit only by moonlight through stained glass and a small shuttered lantern. At the base of a stone altar holding an ancient sword, a loose floor slab has been lifted, revealing a hidden magical device: a tangle of copper wires wrapped with glowing runes around a pulsing crystal core, humming with faint golden light. A lean young man with straw-blond hair kneels beside it, his face lit from below in shock. In the background by a side door, a young woman with short black hair and a red scarf, wearing a dark grey leather coat, keeps watch with a dagger in hand. Tense, secretive mood. Semi-realistic anime painterly illustration with a subtle pixel-art texture, deep blue shadows with warm golden accents, no text.
```

### P1-4　结局·众人之剑（真结局）

```
Cinematic 16:9 illustration in the great plaza before a white-marble cathedral, crowds murmuring in shock. A lean young man about 20 with messy straw-blond hair stands on the steps, having just confessed the truth, his plain sword lowered and not glowing. Beside him, a scarred middle-aged knight in dark navy plate armor has drawn his sword and planted it point-down at his side in a gesture of loyalty. Stepping forward behind them: an elderly scholar with round glasses holding an old book, a young woman in a red scarf with a crooked grin, a 15-year-old apprentice girl with a sage-green ribbon headband, tearful but determined. Morning light breaking through clouds. Hopeful, triumphant, human. Semi-realistic anime painterly illustration with a subtle pixel-art texture, warm golden palette, no text.
```

### P1-5　结局·完美的谎言

```
Cinematic 16:9 illustration of a triumphant victory parade in a medieval fantasy capital, flower petals in the air, cheering crowds and banners with a sun-and-sword sigil. On the cathedral steps, an elderly silver-haired high priest in white and gold vestments places a laurel wreath on the head of a young man with straw-blond hair in white-and-gold ceremonial armor, leaning in to whisper in his ear. The young man smiles for the crowd, but his eyes are hollow and empty. Bright festive colors with an unsettling cold undertone. Semi-realistic anime painterly illustration with a subtle pixel-art texture, no text.
```

### P1-6　结局·替罪羊

```
Cinematic 16:9 illustration in front of a grand white-marble cathedral. An elderly silver-haired high priest in white and gold vestments stands before an ancient sword on its altar, holding up an official proclamation scroll and reading it to a vast silent crowd. In the foreground, a young man with messy straw-blond hair, stripped of his ceremonial tunic, is held by two temple guards in white and gold, his head bowed. The crowd watches coldly; no one speaks for him. Overcast grey morning light. Bleak, betrayed mood. Semi-realistic anime painterly illustration with a subtle pixel-art texture, desaturated cold palette, illegible script on the scroll, no readable text.
```

### P1-7　结局·壮烈殉国

```
Cinematic 16:9 illustration of a city plaza at dusk. A newly unveiled heroic marble statue of an idealized, handsome, muscular "chosen hero" raising a glowing sword stands on a pedestal decorated with fresh flowers and candles; its noble face looks nothing like an ordinary young man. Townspeople lay flowers at its base. In the sky behind, faint snow drifts down. A small worn plain sword lies forgotten among the offerings. Bittersweet, melancholic mood: the world praises him, but no one knows who he really was. Semi-realistic anime painterly illustration with a subtle pixel-art texture, muted cold palette with warm candle accents, no text.
```

### P1-8　结局·逃兵

```
Cinematic 16:9 illustration of a golden wheat field outside a medieval walled city at sunrise. A young woman with short black hair, a red scarf and a dark grey leather coat walks ahead with a cheeky grin, tossing a heavy coin purse in her hand. Behind her, a lean young man with messy straw-blond hair in plain traveler's clothes, his oversized ceremonial tunic tied around his waist, glances back over his shoulder at the distant city and its golden-domed cathedral. A muddy sewer outlet in the city wall behind them. Free, comedic, lighthearted mood. Semi-realistic anime painterly illustration with a subtle pixel-art texture, warm sunrise palette, no text.
```

### P1-9　标题画面主视觉
- 说明：标题文字“假勇者”以后单独加，这里只要画面，左侧或上方留出放标题的空间。

```
Key art for a fantasy game title screen, 16:9. Inside a dim grand cathedral, a lean young man with messy straw-blond hair in an oversized white-and-gold ceremonial tunic stands before an ancient sword set in a stone altar; the sword glows with false golden light from hidden runes beneath the altar. Behind him, cast long across the marble floor and up the wall, looms the enormous shadow of an elderly high priest whose hand reaches toward the young man like a puppeteer's. The young man looks back over his shoulder warily. Leave empty dark space in the upper-left area for a title logo. Mysterious, ironic, dramatic. Semi-realistic anime painterly illustration with a subtle pixel-art texture, deep shadows with golden highlights, no text.
```

---

## P2 —— 次要场景、次要 CG、关键道具

### 场景背景（16:9，完全不透明，不带人物）

#### P2-1　神殿偏厅（第 2 天召见、第 5 天审问）

```
Wide 16:9 interior background of a private side chamber in a grand white-marble cathedral. A smaller, colder room: polished marble floor, a long dark wooden table with high-backed chairs, a heavy curtain half-covering a narrow stained-glass window, golden candelabras, a wall tapestry with a sun disc pierced by a downward sword, shelves with sealed scrolls and ledgers. Elegant but oppressive, a place where decisions are made behind closed doors. Main focus on the left and upper part of the frame. No people. Semi-realistic anime painterly illustration with a subtle pixel-art texture, cool muted palette with candlelight, detailed environment art, game background, fully opaque, no text.
```

#### P2-2　大神殿·正殿（夜）
- 文件：`assets/backgrounds/temple_night.png`（可选，没有时程序自动调暗白天图）

```
Wide 16:9 interior background of a grand white-marble cathedral at night, the same hall as by day but dark and empty. Cold blue moonlight through tall stained-glass windows, a few low-burning candles, long deep shadows between gold-capped columns. On the left third of the image, an ancient sword stands in a stone altar; one floor slab at the altar's base is slightly askew, with a faint golden glow leaking from the crack. Silent, secretive, tense. No people. Semi-realistic anime painterly illustration with a subtle pixel-art texture, deep blue palette with small warm accents, game background, fully opaque, no text.
```

#### P2-3　主角的住处

```
Wide 16:9 interior background of a tiny bare room given to a servant inside a temple compound. Rough stone walls, a narrow straw bed with a thin blanket, a small wooden table with a single oil lamp, a ceremonial white-and-gold tunic hanging on a peg, a wooden shutter window on the left showing the night sky and a crescent moon, a heavy wooden door on the right. Lonely, humble. No people. Semi-realistic anime painterly illustration with a subtle pixel-art texture, warm lamplight against cool shadows, game background, fully opaque, no text.
```

#### P2-4　王都中央广场

```
Wide 16:9 outdoor background of the great central plaza of a medieval fantasy capital, in front of a grand white-marble cathedral with a golden dome and broad stone steps. A raised preaching platform with banners showing a sun disc pierced by a downward sword, a fountain, surrounding townhouses with flower boxes, wide cobblestone space able to hold thousands. Bright morning. No people. Semi-realistic anime painterly illustration with a subtle pixel-art texture, warm muted palette, game background, fully opaque, no text.
```

#### P2-5　王宫宴会厅

```
Wide 16:9 interior background of a royal banquet hall in a medieval fantasy palace at night. A very long table covered with white cloth, silver platters, roast dishes and goblets, rows of golden candelabras, crystal chandeliers, crimson and gold banners, a raised throne at the far end, musicians' gallery above. Lavish, glowing, but with deep shadows in the corners. No people. Semi-realistic anime painterly illustration with a subtle pixel-art texture, rich warm candlelight palette, game background, fully opaque, no text.
```

### 次要 CG（16:9）

#### P2-6　大祭司扶起你（第 1 天）

```
Cinematic 16:9 close-up illustration inside a golden-lit cathedral. An elderly silver-haired high priest in white and gold vestments with purple trim bends down to help a kneeling young man with straw-blond hair in an oversized white-and-gold ceremonial tunic to his feet, leaning close to whisper in his ear. The priest's expression is gentle on the surface, but his eyes are cold and calculating; his pale hand grips the young man's wrist. The young man's eyes widen with dawning realization. Blurred kneeling crowd and golden light in the background. Semi-realistic anime painterly illustration with a subtle pixel-art texture, warm light with cold undertones, no text.
```

#### P2-7　考验失败

```
Cinematic 16:9 illustration in a knights' training ground. A lean young man with straw-blond hair in an oversized white-and-gold ceremonial tunic has swung a plain sword into an iron-banded oak post; the blade is stuck in the iron band, bent slightly, sparks fading. His face is pale. Surrounding knights and townspeople gasp, whisper and point. A scarred knight in dark navy plate armor closes his eyes and shakes his head. Semi-realistic anime painterly illustration with a subtle pixel-art texture, harsh afternoon light, no text.
```

#### P2-8　考验“成功”（作弊）

```
Cinematic 16:9 illustration in a knights' training ground. A lean young man with straw-blond hair in an oversized white-and-gold ceremonial tunic follows through a sword swing as an iron-banded oak post splits cleanly in two, wood chips flying, a burst of soft white light around the blade. The crowd of knights and townspeople erupts in cheers. In the corner of the crowd, a 15-year-old apprentice girl with a sage-green ribbon headband secretly lowers her glowing hand behind her tome, and nearby a young woman in a red scarf leans against a fence, smirking. A scarred knight in navy armor narrows his eyes. Semi-realistic anime painterly illustration with a subtle pixel-art texture, bright dramatic light, no text.
```

#### P2-9　不速之客（第 6 天夜）

```
Cinematic 16:9 night illustration from inside a tiny bare servant's room. The wooden shutter window has just swung open; a young woman with short black hair, a red scarf and a dark hooded grey leather coat crouches on the windowsill, backlit by a large moon over city rooftops, casually twirling a dagger in greeting with a playful grin. In the foreground, a lean young man with straw-blond hair, about to blow out an oil lamp, freezes in surprise. Semi-realistic anime painterly illustration with a subtle pixel-art texture, cool moonlight and warm lamplight, no text.
```

#### P2-10　出征前夜宴（第 7 天夜）

```
Cinematic 16:9 illustration of a lavish royal banquet hall at night, golden candlelight and chandeliers. At the head of a long table, a portly older king with a grey beard and gold crown raises a goblet in a toast. Nobles in fine clothes raise their glasses. Among the guests: a scarred knight in navy armor, an elderly scholar with round glasses, a brown-haired apprentice girl with a sage-green headband, a silver-haired high priest in white and gold watching from the side, and a young woman in a red scarf disguised as a servant. At the center, a lean young man with straw-blond hair in white-and-gold ceremonial attire holds his goblet, looking around at all of them, uncertain. Semi-realistic anime painterly illustration with a subtle pixel-art texture, rich warm palette, no text.
```

### 酒馆老板娘立绘

#### P2-11　酒馆老板娘
- 文件：`assets/portraits/tavern_keeper.png`（目前游戏里还没有这个角色，先画好备用）

```
Half-body character portrait (head to mid-thigh), 3/4 view, standing, vertical 2:3 composition, head in the upper quarter of the frame. A sharp-eyed tavern keeper woman in her late thirties, auburn hair tied up in a loose bun with a few strands falling, rolled-up sleeves, a mustard-yellow bodice over a cream blouse, a stained apron, wiping a pewter mug with a cloth, a knowing half-smile as if she has heard every rumor in town. Semi-realistic anime painterly illustration with a subtle pixel-art texture, muted warm medieval fantasy palette, soft rim lighting. Plain flat light-grey background for easy background removal, no text.
```

### 关键道具（正方形 256×256 图标，生成时可以用 1024×1024 再缩小）

通用后缀（下面每段已包含）：*game item icon, centered single object, semi-realistic anime painterly style with a subtle pixel-art texture, soft top-left lighting, plain flat light-grey background for easy background removal, no text.*

#### P2-12　圣剑（不发光）
```
An ancient longsword with a worn silver blade and a gold-wrapped hilt, a small sun disc emblem on the crossguard, slightly tarnished and ordinary-looking, displayed diagonally. Game item icon, centered single object, semi-realistic anime painterly style with a subtle pixel-art texture, soft top-left lighting, plain flat light-grey background for easy background removal, no text.
```

#### P2-13　剑座与魔导装置
```
A carved white stone sword pedestal shown in cutaway, revealing a hidden magical device inside its base: a tangle of copper wires wrapped with glowing golden runes around a pulsing crystal core. Game item icon, centered single object, semi-realistic anime painterly style with a subtle pixel-art texture, soft top-left lighting, plain flat light-grey background for easy background removal, no text.
```

#### P2-14　符文核心（关键实证）
```
A small palm-sized brass and crystal device core, engraved with glowing golden runes and a temple emblem of a sun disc pierced by a downward sword, broken copper wires dangling from it. Game item icon, centered single object, semi-realistic anime painterly style with a subtle pixel-art texture, soft top-left lighting, plain flat light-grey background for easy background removal, no text.
```

#### P2-15　两份公告
```
Two official parchment proclamations side by side, each sealed with a gold wax seal bearing a sun-and-sword emblem, written in illegible ornate script, one with a black mourning ribbon and one with a red accusatory stamp, the date line on both left blank. Game item icon, centered, semi-realistic anime painterly style with a subtle pixel-art texture, soft top-left lighting, plain flat light-grey background for easy background removal, no readable text.
```

#### P2-16　古籍
```
A thick ancient leather-bound tome lying open, yellowed pages showing illegible script and a diagram of a black crystal heart inside a sealing circle, a ribbon bookmark, brass corner guards. Game item icon, centered single object, semi-realistic anime painterly style with a subtle pixel-art texture, soft top-left lighting, plain flat light-grey background for easy background removal, no readable text.
```

#### P2-17　黑曜心核
```
A jagged obsidian crystal heart, black and glossy with dark purple veins pulsing faintly inside, cold mist curling around it. Game item icon, centered single object, semi-realistic anime painterly style with a subtle pixel-art texture, soft top-left lighting, plain flat light-grey background for easy background removal, no text.
```

#### P2-18　钱袋
```
A heavy brown leather coin purse tied with a cord, gold coins spilling out. Game item icon, centered single object, semi-realistic anime painterly style with a subtle pixel-art texture, soft top-left lighting, plain flat light-grey background for easy background removal, no text.
```

#### P2-19　包铁橡木桩
```
A thick oak training post wrapped with three riveted iron bands, standing upright in sand, scarred by old sword cuts. Game item icon, centered single object, semi-realistic anime painterly style with a subtle pixel-art texture, soft top-left lighting, plain flat light-grey background for easy background removal, no text.
```

---

## P3 —— 扩展角色、隐藏结局、图标、UI

### 扩展角色立绘（2:3，透明背景）

#### P3-1　国王（重绘）
```
Half-body character portrait (head to mid-thigh), 3/4 view, standing, vertical 2:3 composition, head in the upper quarter of the frame. A portly older king in his sixties with a neatly trimmed grey beard and a heavy gold crown, crimson and gold royal robes with thick white fur trim, rings on his fingers, holding a jeweled goblet. He wears a practiced public smile, but his eyes are impatient and calculating: a ruler who cares only about results and his own reputation. Semi-realistic anime painterly illustration with a subtle pixel-art texture, muted warm medieval fantasy palette, soft rim lighting. Plain flat light-grey background for easy background removal, no text.
```

#### P3-2　魔王的间谍（重绘）
```
Half-body character portrait (head to mid-thigh), 3/4 view, standing, vertical 2:3 composition, head in the upper quarter of the frame. A friendly-looking traveling merchant in his thirties with neat dark auburn hair and a warm, disarming smile, plain brown coat, a satchel and an account ledger under his arm. Subtle wrong details: his pupils are faintly slit and violet, a shadow at his feet is slightly too long, a small black ring with a horned sigil on one finger. Approachable on the surface, quietly unsettling underneath. Semi-realistic anime painterly illustration with a subtle pixel-art texture, muted warm medieval fantasy palette, soft rim lighting. Plain flat light-grey background for easy background removal, no text.
```

#### P3-3　神殿护卫
```
Half-body character portrait (head to mid-thigh), front view, vertical 2:3 composition. A stern temple guard in polished white and gold half-plate armor with a white tabard showing a golden sun disc pierced by a downward sword, a halberd in hand, a helmet with a narrow visor hiding the eyes, an emotionless and intimidating presence. Semi-realistic anime painterly illustration with a subtle pixel-art texture, muted palette, soft rim lighting. Plain flat light-grey background for easy background removal, no text.
```

### 次要 CG（16:9）

#### P3-4　大祭司的“关照”（第 2 天清晨）
```
Cinematic 16:9 illustration in the pre-dawn gloom. Two tall temple guards in white and gold half-plate armor with sun-and-sword tabards stand blocking the doorway of a tiny servant's room, faces hidden by visors. Inside, a lean young man with messy straw-blond hair, just woken, sits up on a straw bed, staring at them. Cold blue dawn light, oppressive atmosphere. Semi-realistic anime painterly illustration with a subtle pixel-art texture, no text.
```

#### P3-5　布道大会 / 审问（第 5 天）
```
Cinematic 16:9 illustration in a cold marble side chamber of a cathedral. An elderly silver-haired high priest in white and gold vestments sits at the head of a long dark table, fingers steepled; several senior priests in white robes stand silently behind him in a row. A lean young man with straw-blond hair in an oversized white-and-gold ceremonial tunic stands alone before them. Through a half-curtained window, a huge crowd in the plaza below is visible. Interrogation mood, tense silence. Semi-realistic anime painterly illustration with a subtle pixel-art texture, cool palette with candlelight, no text.
```

#### P3-6　夜潜被抓
```
Cinematic 16:9 night illustration inside a dark cathedral. A lean young man with straw-blond hair, crouching beside a lifted floor slab at the base of a sword altar, freezes as the harsh beam of a lantern hits him. In the foreground, the silhouette of a night-watch priest in a hooded white robe raises the lantern. Deep blue darkness, startled moment. Semi-realistic anime painterly illustration with a subtle pixel-art texture, no text.
```

### 隐藏结局 CG（Demo 未实现）

#### P3-7　结局·反客为主
```
Cinematic 16:9 illustration inside a grand cathedral. A young man with straw-blond hair, now wearing white and gold high-priest vestments, stands calmly before the sword altar, holding up a small glowing brass rune core engraved with a sun-and-sword emblem. Before him, an elderly silver-haired high priest kneels on the marble floor, head bowed in defeat. The young man's face is calm and unreadable, a hint of the same cold smile the old priest once had. Gray morality, quiet power shift. Semi-realistic anime painterly illustration with a subtle pixel-art texture, golden light with heavy shadows, no text.
```

#### P3-8　结局·魔王的交易
```
Cinematic 16:9 illustration in a dark tavern back room lit by one candle. A friendly-looking merchant peels away his disguise: his shadow on the wall behind him grows into a vast horned demonic silhouette with glowing violet eyes. Across the table, a young man with straw-blond hair sits with a contract scroll in front of him, quill in hand, hesitating. Ominous, seductive mood. Semi-realistic anime painterly illustration with a subtle pixel-art texture, dark palette with violet and candle-orange accents, illegible script, no readable text.
```

### 场景补充

#### P3-9　王都地图（夜景）
- 文件：可选，没有时程序自动调暗白天图。**用 P0-7 的成品作参考图**，保证布局一致。
```
The same top-down three-quarter view illustrated map of a small medieval fantasy royal capital, 16:9, at night: deep blue moonlit sky tones, warm glowing windows in houses, lanterns along the roads, the tavern at the lower left brightly lit, the cathedral dome at the top center catching moonlight, the slums at the lower right in deep shadow. Same layout as the daytime map. Semi-realistic anime painterly illustration with a subtle pixel-art texture, fully opaque, no text, no labels.
```

#### P3-10　夜幕降临过场
```
Wide 16:9 illustration of a medieval fantasy capital skyline at nightfall, seen from a hill: silhouettes of rooftops, a golden-domed cathedral and a blue library tower against a deep indigo sky with the first stars and a crescent moon, scattered warm window lights, soft mist. Quiet, contemplative. Leave the lower third darker for overlay text. Semi-realistic anime painterly illustration with a subtle pixel-art texture, fully opaque, no text.
```

### 事实图标（手记“你知道的事”，正方形 256×256）

通用后缀：*flat painted game UI icon, centered single symbol, semi-realistic anime painterly style with a subtle pixel-art texture, gold and parchment palette, plain flat dark background, no text.*

| # | 事实 | Prompt |
|---|---|---|
| P3-11 | 仪式是假的 | `A golden halo of light around a sword cracking apart into shards, flat painted game UI icon, centered single symbol, semi-realistic anime painterly style with a subtle pixel-art texture, gold and parchment palette, plain flat dark background, no text.` |
| P3-12 | 圣剑发光靠魔导装置 | `A brass gear interlocked with glowing golden runes and copper wires, flat painted game UI icon, centered single symbol, semi-realistic anime painterly style with a subtle pixel-art texture, gold and parchment palette, plain flat dark background, no text.` |
| P3-13 | 勇者没有神力 | `An open empty human palm with faint fading sparkles above it, nothing there, flat painted game UI icon, centered single symbol, semi-realistic anime painterly style with a subtle pixel-art texture, gold and parchment palette, plain flat dark background, no text.` |
| P3-14 | 大祭司是主谋 | `A tall white and gold high priest's mitre casting a long dark shadow shaped like puppet strings, flat painted game UI icon, centered single symbol, semi-realistic anime painterly style with a subtle pixel-art texture, gold and parchment palette, plain flat dark background, no text.` |
| P3-15 | 勇者是替罪羊 | `A small goat figure standing on two sealed parchment proclamations, flat painted game UI icon, centered single symbol, semi-realistic anime painterly style with a subtle pixel-art texture, gold and parchment palette, plain flat dark background, no text.` |
| P3-16 | 魔王的弱点 | `A black obsidian crystal heart inside a golden sealing circle under an eclipsed moon, flat painted game UI icon, centered single symbol, semi-realistic anime painterly style with a subtle pixel-art texture, gold and parchment palette, plain flat dark background, no text.` |
| P3-17 | 诺娃的目击证词 | `A watchful eye above a crossed dagger and a red scarf, flat painted game UI icon, centered single symbol, semi-realistic anime painterly style with a subtle pixel-art texture, gold and parchment palette, plain flat dark background, no text.` |

### 界面小图标（正方形 256×256）

通用后缀同上。

| # | 图标 | Prompt |
|---|---|---|
| P3-18 | 上午 | `A rising sun over rooftops with soft pink morning light, flat painted game UI icon, centered single symbol, semi-realistic anime painterly style with a subtle pixel-art texture, plain flat dark background, no text.` |
| P3-19 | 下午 | `A bright full sun with short rays, flat painted game UI icon, centered single symbol, semi-realistic anime painterly style with a subtle pixel-art texture, plain flat dark background, no text.` |
| P3-20 | 傍晚 | `A setting orange sun half-sunk behind a horizon with a lantern lighting up, flat painted game UI icon, centered single symbol, semi-realistic anime painterly style with a subtle pixel-art texture, plain flat dark background, no text.` |
| P3-21 | 夜晚 | `A crescent moon with a few stars, flat painted game UI icon, centered single symbol, semi-realistic anime painterly style with a subtle pixel-art texture, plain flat dark background, no text.` |
| P3-22 | 疑云值 | `A dark storm cloud with a single half-open suspicious eye inside it, flat painted game UI icon, centered single symbol, semi-realistic anime painterly style with a subtle pixel-art texture, plain flat dark background, no text.` |
| P3-23 | 共犯标记 | `Two hands clasped in a secret handshake over a broken golden halo, flat painted game UI icon, centered single symbol, semi-realistic anime painterly style with a subtle pixel-art texture, plain flat dark background, no text.` |
| P3-24 | 地点徽记·神殿 | `A golden sun disc pierced by a downward sword on a white shield, flat painted game UI emblem, centered, semi-realistic anime painterly style with a subtle pixel-art texture, plain flat dark background, no text.` |
| P3-25 | 地点徽记·训练场 | `Two crossed swords over a navy blue shield, flat painted game UI emblem, centered, semi-realistic anime painterly style with a subtle pixel-art texture, plain flat dark background, no text.` |
| P3-26 | 地点徽记·图书馆 | `An open book with a quill under a blue tower roof, flat painted game UI emblem, centered, semi-realistic anime painterly style with a subtle pixel-art texture, plain flat dark background, no text.` |
| P3-27 | 地点徽记·酒馆 | `A foaming tankard with a bundle of golden wheat, flat painted game UI emblem, centered, semi-realistic anime painterly style with a subtle pixel-art texture, plain flat dark background, no text.` |
| P3-28 | 地点徽记·下城小巷 | `A hooded lantern and a dagger crossed over a cracked cobblestone, flat painted game UI emblem, centered, semi-realistic anime painterly style with a subtle pixel-art texture, plain flat dark background, no text.` |

> 对话策略标签（说服 / 表演 / 撒谎 / 坦白 / 威胁 / 交易 / 转移）目前用彩色文字表示，效果已经够用，暂不出图标。

### UI

#### P3-29　Logo 底图
- 说明：生图模型写不好“假勇者”三个字，建议只生成徽章底图，文字后期用字体排版叠上去。
```
Game logo emblem without any lettering, wide horizontal format: an ornate golden sword laid horizontally across a cracked golden sun-disc halo, a blank red wax stamp pressed crookedly over the crack like a forged seal, small falling shards of light, a blank banner ribbon across the center for adding a title later. Semi-realistic anime painterly style with a subtle pixel-art texture, gold, ivory and deep crimson palette, plain flat black background, no text.
```

#### P3-30　对话框 / 立绘框边框
```
Ornate rectangular game UI frame, 9-slice friendly: thin dark wood border with worn gold metal corner pieces engraved with sun motifs, a parchment-textured inner panel, symmetrical, clean straight edges, flat front view. Semi-realistic anime painterly style with a subtle pixel-art texture, plain flat black background outside the frame, no text.
```

---

## 汇总

| 优先级 | 编号 | 内容 |
|---|---|---|
| P0 | P0-1 ~ P0-7 | 主角立绘、5 个地点背景（含新正殿）、王都地图 |
| P1 | P1-1 ~ P1-9 | 圣剑择主、考验、发现装置、5 个结局、标题主视觉 |
| P2 | P2-1 ~ P2-19 | 偏厅、正殿夜、住处、广场、宴会厅；5 张次要 CG；老板娘；8 个关键道具 |
| P3 | P3-1 ~ P3-30 | 国王、间谍、护卫；3 张次要 CG；2 张隐藏结局；地图夜景、夜幕过场；7 个事实图标；11 个界面图标；Logo、边框 |

**接入游戏需要我配合的**：
- P0-1 主角立绘、P0-2 ~ P0-6 地点背景：放到指定文件名即可，不用改代码。
- P0-7 地图：换图后告诉我，我来重新对齐 5 个地点的点击区域。
- 过场 CG、道具和图标：目前游戏不显示，等你决定接入时再改代码。
