# 仿淘宝 · 前端界面练习

按淘宝 PC 端(www.taobao.com)的视觉规范搭的一套**纯静态**页面。
零依赖、零后端、零数据库 —— 双击 HTML 就能看。

---

## 快速开始

```
双击 index.html                     # 直接打开
```

或者起个本地服务(推荐,`localStorage` 行为更接近真实环境):

```bash
python -m http.server 8123
# 然后浏览器打开 http://127.0.0.1:8123
```

> 直接用 `file://` 打开也能跑。部分浏览器会禁用 `file://` 下的
> `localStorage`,这种情况购物车会退化成内存存储(刷新即清空),
> 代码里已做兜底,不会报错。

### 下载完整 ABO 小图库

商品索引已经包含全部可用 ABO 商品。首次下载约 3.25GB 的官方 256px 图片包时，在 PowerShell 中运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\import-abo.ps1
```

脚本使用 4 个持续区间连接、默认每连接 512KB/s，支持断点续传；完成后自动校验归档、解压图片、重建索引并运行检查。后台执行时可查看 `data/abo/import.log` 和 `data/abo/import-error.log`。

---

## 页面

| 文件 | 页面 | 内容 |
|---|---|---|
| `index.html` | 首页 | 按 2026-09-26 未登录 PC 首页快照重做：顶栏、搜索、频道、11 行分类、332px 主推荐区、6 列猜你喜欢 |
| `search.html` | 搜索 / 列表 | 左侧分类+价格筛选、排序(综合/销量/新品/价格升降)、已选条件 chips、4 列网格、分页、无结果兜底 |
| `item.html` | 商品详情 | 主图+缩略图(支持 ←/→ 切换)、价格区、规格 SKU 选择、数量、加购/立即购买、店铺卡、详情/评价/参数 Tab |
| `cart.html` | 购物车 | 勾选、增减数量、删除、全选、清空、吸底结算条、金额实时合计 |
| `checkout.html` | 下单结算 | 收货地址、支付方式、商品清单、运费/优惠计算、提交订单 → 下单成功页 |

商品库包含 ABO、DeepFashion、Products-10K、RP2K、Stanford Online Products、Shopify、RPC、FSL、Tari、食品等本地开源数据，并按淘宝首页结构扩展三级分类。每个三级细分类都拥有独立商品池，当前最少为 **200 件**，不存在空分类。页面只水合当前一页，不会把完整商品对象一次塞进内存；首页图片采用懒加载。

“集运”和“回国行李”均可检索到 **464 件**静态商品。`assets/products/taobao/集运/` 中保存了当前登录搜索页低频取得的 44 张相关商品图，均已去重并接入物流商品池；其来源清单保存在 `data/taobao-live/`。

购物车数据存在 `localStorage`,**跨页面共享** —— 详情页加购,购物车页就能看到。

---

## 目录结构

```
.
├── index.html / search.html / item.html / cart.html / checkout.html
├── css/
│   ├── base.css      设计变量 + 重置 + 公共组件(顶栏/头部/导航/页脚/按钮/商品卡)
│   ├── home.css      首页(三栏 Hero、分类树、楼层)
│   ├── list.css      列表页(筛选栏、排序条、分页)
│   ├── item.css      详情页(主图区、规格选择、Tab)
│   └── cart.css      购物车 + 结算 + 下单成功
└── js/
    ├── data.js       ★ 商品数据（首页快照商品 + 练习数据）、分类树、热词和图片配置
    ├── *-products.js 开源数据集生成的紧凑商品索引
    ├── common.js     布局注入、图片兜底、搜索框、购物车存储、轻提示
    ├── home.js / list.js / item.js / cart.js    各页逻辑
```

顶栏 / 头部 / 主导航 / 页脚由 `common.js` 的 `mountLayout()` 注入到
每个页面里的 `<div id="site-head">` 和 `<div id="site-foot">`,改一处全站生效。

---

## 常见改动

### 换商品 / 加商品

编辑 `js/data.js` 里的 `RAW_PRODUCTS`,每行一个商品:

```js
// [标题, 现价, 原价, 销量, 店铺, 发货地, 图片ID或本地路径, 分类, 来源, 来源ID]
['2025新款韩版显瘦连衣裙 夏季收腰长裙', 129.00, 259.00, 8421, '衣品汇旗舰店', '浙江 杭州', '1475180098004-ca77a66827be', '女装'],
```

「图片ID」可以是 Unsplash 照片网址里 `photo-` 后面那串，也可以直接写 `assets/` 下的本地图片路径。
分类字段自由填 —— `search.html` 左侧的分类筛选是**从商品数据里自动生成的**,
加一个新分类不用改别的代码。分类名同时决定:

- **详情页主图组**:同分类的图会自动轮换凑满 5 张,风格不会串(补不满时只从
  `CAT_RELATED` 里写的相邻分类借,比如「手表」借「珠宝」的图)。
- **规格选项**:在 `js/item.js` 的 `specsFor()` 里按分类配(没配的走「女装」兜底)。

### 换首页楼层

`js/data.js` 的 `HOME_FLOORS`。每层由多个分类拼成,拼够 10 个商品
(5 列 × 2 行)才不会空一列:

```js
{ cats: ['女装', '男装'], title: '女装 / 男装', sub: '当季新品 一件包邮' },
```

自己写死商品列表也可以 —— 改 `js/home.js` 里的 `renderFloors()`。

### 换配色 / 字号 / 圆角

全在 `css/base.css` 顶部的 `:root` 里:

```css
:root {
  --orange: #ff5000;        /* 主色,改这里整站跟着变 */
  --container: 1190px;      /* 页面宽度 */
  --font: -apple-system, ... "Microsoft YaHei", sans-serif;
}
```

### 换成自己的图片

`js/data.js` 顶部的 `SITE.img` 是整个项目的图片出口,全站图片都从这里走:

```js
const SITE = {
  // 改成本地文件:把 RAW_PRODUCTS 的「图片ID」换成文件名即可
  img: (id, w = 400, h = 400) => `assets/${id}.jpg`,
};
```

然后在根目录建 `assets/` 放图。图片加载失败会自动换成灰色 SVG 占位符
(逻辑在 `common.js` 的 `FALLBACK_IMG`),不会出现破图图标。

二维码和评价头像不走 `SITE.img` —— 它们是 `data.js` 里 `qrSvg()` / `avatarSvg()`
用 SVG 现画的(data URI),不联网、不占体积,断网也是正常显示。

---

## 和真淘宝的差距

**能做到的**:当前未登录首页的 1280px 内容宽度、256px 左右栏、332px 主推荐区、
6 列商品流、顶栏/搜索框/导航的结构与位置、橙色主色 `#ff5000`、
价格字号、卡片圆角与阴影，以及详情页等本地交互。

**做不到的**:

- **逐像素一致**。淘宝的 CSS 是构建时动态生成的,class 名是哈希串,
  拿不到真实源码;字体是自有字体(阿里巴巴普惠体),不能合法嵌入。
- **图标和 Logo**。淘宝的图标是自绘 SVG sprite,Logo 是注册商标,
  这里是按同样的视觉语言重画的,不是原件。
- **动态部分**。千人千面推荐、实时价格、直播入口这些需要真实后端,
  静态站只有本地假数据。
- **历史种子图片**。少量早期种子商品仍使用公网 CDN 照片；新导入的 ABO、时尚和 Products-10K 商品均使用数据集自带并已缓存到本地的对应图片。

所以整体观感约 **90%**;剩下 10% 是字体、图标和动态内容。
想再逼近,只能对着真实截图一处一处校尺寸和间距。

---

## 说明

- 本项目是**前端界面练习作品**,非淘宝官方网站,与阿里巴巴集团无关。
- 「淘宝」是阿里巴巴集团的注册商标。**仅供本地学习研究使用,
  请勿部署到公网或用于任何商业用途** —— 真要上线,请把 `js/common.js`
  里的站点名、`index.html` 的 `<title>` 和页脚版权行换掉。
- ABO 样本的商品名称、品牌和主图来自数据集；价格、销量、店铺展示名和发货地是静态演示数据。其余商品信息仍可能包含虚构内容。

### 图片说明

- 完整 ABO 索引包含 147,127 件可用商品和 398,212 条图片映射。256px 官方小图由 `scripts/import-abo.ps1` 使用少量持续区间请求、限速及断点续传下载，解压至 `assets/products/abo/images/small/`；不会逐张访问图片服务器。生成的浏览器索引位于 `js/abo-products.js`。
- 三级分类由 `scripts/build-detail-products.mjs` 和 `scripts/build-taxonomy-products.mjs` 生成独立商品池，每类至少 200 件；运行 `node scripts/verify-catalog.mjs` 可检查总量、空分类、搜索结果和 DeepFashion 图片完整性。
- 集运图片来自登录后的淘宝集运搜索首屏，按最多 8 张一批、无并发、无翻页的方式低频保存；44 张图片的哈希互不重复。仅供本地教学演示，不应对外发布或用于商业用途。
- `fashion-product-images-small` 已导入 22,036 件带真实标题、品类属性和内嵌图片的时尚商品；Products-10K 已先行导入 6,667 件完整分片商品。两者的图片均从 Parquet 文件一次性解出到 `assets/products/open/`，不会逐张请求原站。
- 后续开源集由 `scripts/download-open-datasets.py` 和 `scripts/download-more-open-datasets.py` 串行下载：全程 1 个连接、总限速 2 MiB/s、支持断点续传，每个文件之间暂停 8 秒。实时状态见 `data/open/download-status.json`、`data/open/download-more-status.json` 和对应日志。
- 前 12 件效果样本同样来自 [Amazon Berkeley Objects（ABO）](https://amazon-berkeley-objects.s3.amazonaws.com/index.html)，并单独缓存在 `assets/products/abo-sample/`，保证完整归档下载期间首页仍有可预览内容。数据和图片署名 Amazon.com，数据集构建者与完整许可信息见其官方页面；本项目对少量中文标题做了空格、单位和大小写整理。
- 练习商品图来自 [Unsplash](https://unsplash.com),按
  [Unsplash License](https://unsplash.com/license) 授权(可免费商用、无需署名,
  这里出于尊重列出)。图片 URL 带 `w` / `h` / `fit=crop` 参数,
  由 Unsplash 的 CDN 实时裁剪,所以仓库里没有任何图片文件。
- 首页快照的前 18 件商品使用获取快照时公开展示的图片 URL，仅用于本地学习；
  其余照片只是"看起来对"的占位素材，不保证图片内容与商品标题完全对应
  (比如「空气炸锅」用的是一张烤箱照片)。真要用请换成自己的商品图。
- 已刻意避开带明显第三方商标的照片(Nike / Apple / Chanel / Prada / JBL 等),
  但 Unsplash 图片的模特肖像权、商标权需要你自己复核。
- 图片走的是公网 CDN,**离线打开会退化成灰色占位符**(不会报错)。
  想完全离线,按上面「换成自己的图片」改成本地文件即可。
