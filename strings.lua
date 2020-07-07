local descEN = [[This mod helps you build some road layout which is difficult or impossible to do with the vanilla game.
It's possible to built two road layouts with this tool:
1. sharp road bifurcation
2. Parallel roads

1. Sharp bifurcation
By the vanilla road tools of the game, the bifurcation angle of road is limited, are the players are not able to build sharp bifurcations. However, with the "Sharp bifurcation" function of this mod, it's now possible.
Switch to the bifurcation mode and drag the road, the mod will rectrify the road afterwards.
The build comes with following restrictions:
- There must be an existing road section without junction and whose length is equal or longer than the part to build, if not the mod will do nothing
- Not working with crossing

2. Parallel roads
This mode helps you build roads parallelly.
Just switch parallel mode and drag the road, the mod will create parallel roads automatically. In case of even number of roads to build, there will be one road more on left than the right.

* This mod can be safely removed from gamesaves.

Stay strong and united facing COVID-19!

Changelogs:
1.2
- Intregration of the options into menu
- Change of spacing range
- Cancel of one-way conversion
- Fix for some crashes
1.1 
- Adaptation to the new API
- New UI for the parallel roads
- Compatibility to all streets and bridges
]]

local descFR = [[Ce mod vous aide à construire des dispositions de route qui sont difficile ou impossible à faire avec le jeu original.
Il est possible de construire deux dispositions de route :
1. Bifurcation à petit angle
2. Routes en parallèle

1. Bifurcation à petit angle
Par les outils routiers originales du jeu, l'angle de bifurcation de la route est limité, et les joueurs ne sont pas en mesure de construire des bifurcations à petit angles. Avec la fonction "Bifurcation à petit angle" de ce mod, c'est désormais possible.
Passez en mode bifurcation et faites glisser la route, le mod la rectifiera ensuite.
Il existe les restrictions suivantes :
- Il doit y avoir un tronçon de route existant sans jonction et dont la longueur est égale ou supérieure à la partie à construire, sinon le mod ne fera rien
- Ne fonctionne pas avec le croisement

2. Routes parallèles
Ce mode vous aide à construire des routes en parallèle.
Changez simplement de mode parallèle et faites glisser la route, le mod créera ensuite les routes parallèles. Si le nombre de voie est en pair, il y aura une voie plus à gauche que à droite.

* Ce mod pourrait être désactivé sans souci.

Restons pridents! #COVID19

Changelogs:
1.2
- Intrégration des options dans le menu
- Modification de l'intervalle d'écart
- Annulation de conversion automatique de voie sens-unique.
- Correction des buges de plantage.
1.1 
- Adaptation à la nouvelle api, les vieux défaillances sont régelées.
- Nouvelle IHM pour les routes parallèles.
- Compatibilité avec tous les routes et ponts.
]]

local descCN = [[本模组可以帮助玩家建造原游戏无法或者很难建造的道路布局
目前有两种功能：
1. 小角度匝道
2. 平行路

1. 小角度匝道
原装的游戏工具会限制道路的交叉角度，如果角度过小，游戏就会造出弯曲的道路。本功能能够帮助玩家建造非常长并且是笔直的匝道。
在匝道模式下拖动道路，在建造完后模组会将新建的匝道变得笔直。
该功能有两个局限：
- 在新建闸道侧面的道路长度必须比匝道更长，并且这段距离上没有和其他的道路交会，否则模组会放弃建造。
- 如果新建的匝道中间有和其他道路的交会，那么模组也会放弃建造。

2. 平行路
该模式可以在新建道路后自动添加与其平行的道路，如果轨道数量为偶数，那么左侧会比右侧多一条。

* 该模组可以安全地从存档中移除

更新日志：
1.2
- 将选项集成到了菜单中
- 修改了间距的可用范围
- 需求了自动转换为单行道的功能
- 修正了一些会导致游戏崩溃的错误
1.1
- 适配了新版的API
- 改进了平行路的界面
- 兼容了所有的道路和桥梁
]]

local descTC = [[本模組可以幫助玩家建造原遊戲無法或者很難建造的道路佈局
目前有兩種功能：
1. 小角度匝道
2. 平行路

1. 小角度匝道
原裝的遊戲工具會限制道路的交叉角度，如果角度過小，遊戲就會造出彎曲的道路。本功能能夠幫助玩家建造非常長並且是筆直的匝道。
在匝道模式下拖動道路，在建造完後模組會將新建的匝道變得筆直。
該功能有兩個局限：
- 在新建閘道側面的道路長度必須比匝道更長，並且這段距離上沒有和其他的道路交會，否則模組會放棄建造。
- 如果新建的匝道中間有和其他道路的交會，那麼模組也會放棄建造。

2. 平行路
該模式可以在新建道路後自動添加與其平行的道路，如果軌道數量為偶數，那麼左側會比右側多一條。

* 該模組可以安全地從存檔中移除

更新日誌：
1.2
- 將選項集成到了功能表中
- 修改了間距的可用範圍
- 需求了自動轉換為單行道的功能
- 修正了一些會導致遊戲崩潰的錯誤
1.1
- 適配了新版的API
- 改進了平行路的介面
- 相容了所有的道路和橋樑]]

function data()
    return {
        en = {
            MOD_NAME = "Road Toolbox",
            MOD_DESC = descEN,
            ROAD_TOOLBOX = "Road Toolbox",
            SPACING = "Spacing",
            METER = "m",
            ONE_WAY = "Build as One Way (if possible)",
            P_ROADS = "Parallel roads",
            SHARP_XING = "Sharp bifurcation",
            NB_ROADS = "Number of parallel roads"
        },
        fr = {
            MOD_NAME = "Boîte à outil route",
            MOD_DESC = descFR,
            ROAD_TOOLBOX = "Boîte à outil route",
            SPACING = "Espacement",
            METER = "m",
            ONE_WAY = "Sens unique (si possible)",
            P_ROADS = "Voies parallèles",
            SHARP_XING = "Bif. à petit angle",
            NB_ROADS = "Nombre des voies parallèles"
        },
        zh_CN = {
            MOD_NAME = "道路工具",
            MOD_DESC = descCN,
            ROAD_TOOLBOX = "道路工具",
            SPACING = "间距",
            METER = "米",
            ONE_WAY = "转换为单行道(若可能)",
            P_ROADS = "平行道路",
            SHARP_XING = "小角度匝道",
            NB_ROADS = "平行道路数量"
        },
        zh_TW = {
            MOD_NAME = "道路工具",
            MOD_DESC = descTC,
            ROAD_TOOLBOX = "道路工具",
            SPACING = "間距",
            METER = "公尺",
            ONE_WAY = "轉換為單行道(若可能)",
            P_ROADS = "平行道路",
            SHARP_XING = "小角度匝道",
            NB_ROADS = "平行道路數量"
        }
    }
end
