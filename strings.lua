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
Just switch parallel mode and drag the road, the mod will convert them into two parallel roads afterward.
There's option order the mod to convert the road to equivalant one-way roads or just generate parallel road of same type. There is also an option to change the spacing between two roads generated, please note if the spacing is larger that the original road created, the original raod will be kept after built.

* This mod can be safely removed from gamesaves.

Stay strong and united facing COVID-19!

Changelogs:
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
Changez simplement de mode parallèle et faites glisser la route, le mod les convertira ensuite en deux routes parallèles.
Il existe une option pour que le mod convertisse la route en routes à sens unique équivalentes ou génère simplement deux routes en parallèles du même type. Il y a aussi une option pour changer l'espacement entre deux routes générées, veuillez noter que si l'espacement est plus grand que la route d'origine créée, la route d'origine sera conservée après la construction.

* Ce mod pourrait être désactivé sans souci.

Restons pridents! #COVID19

Changelogs:
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
该模式可以在新建道路后将其自动转换为两条平行的道路。该模式下有一个选项，可以设定是直接创建两条相同类型的道路还是转换为同样宽度的单行道。此外还有一个选项用于设置平行道路的间距。
注意如果平行道路间距大于原道路，则原道路会自动保留。

* 该模组可以安全地从存档中移除

更新日志：
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
該模式可以在新建道路後將其自動轉換為兩條平行的道路。該模式下有一個選項，可以設定是直接創建兩條相同類型的道路還是轉換為同樣寬度的單行道。此外還有一個選項用於設置平行道路的間距。
注意如果平行道路間距大於原道路，則原道路會自動保留。

* 該模組可以安全地從存檔中移除

更新日誌：
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
            TITLE = "Parallel roads"
        },
        fr = {
            MOD_NAME = "Boîte à outil route",
            MOD_DESC = descFR,
            ROAD_TOOLBOX = "Boîte à outil route",
            SPACING = "Espacement",
            METER = "m",
            ONE_WAY = "Sens unique (si possible)",
            TITLE = "Routes parallèles"
        },
        zh_CN = {
            MOD_NAME = "道路工具",
            MOD_DESC = descCN,
            ROAD_TOOLBOX = "道路工具",
            SPACING = "间距",
            METER = "米",
            ONE_WAY = "转换为单行道(若可能)",
            TITLE = "平行道路"
        },
        zh_TW = {
            MOD_NAME = "道路工具",
            MOD_DESC = descTC,
            ROAD_TOOLBOX = "道路工具",
            SPACING = "間距",
            METER = "公尺",
            ONE_WAY = "轉換為單行道(若可能)",
            TITLE = "平行道路"
        }
    }
end
