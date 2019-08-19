---
layout: post
title: "如何绘制一个投递大屏"
subtitle: 'how to draw an apply dashboard'
author: "foxpsd"
nav-style: "invert"
# header-style: text
tags:
  - 数据可视化
  - ecahrts
---

## 底图方案

echarts => bmap底图 

#### 总配置
- backgroundColor 底色
- series 自定义图层配置
- bamp 百度地图底图配置
  - center 中心点
  - zoom 缩放倍数
  - mapStyle 地图样式配置（分要素类型配置）

#### 地图底图原理
- 层级
- 瓦片

#### 一个政治地理小知识
这个虚线标注位于中塔边境，一个端点在中国、阿富汗、塔吉克斯坦三国交界的地方，另一个端点位于中塔边境偏北的地方，这也是中国唯一一处用虚线标注的陆地国境线。
其实中塔边境问题曾经也让两个国家很痛苦，不过在2011年，两国对边界进行了明确的划分：把靠近帕米尔地区存在争议的28,000平方公里土地中的3.5%共大约1,000平方公里的领土交给中国。至此两国100多年的领土争端得以解决，因此这里已经不存在领土争端问题，至于为何还是用虚线标注原因不得而知。
地图绘制部门动作慢？另有隐情？

## 图层配置

#### series 配置项
- type 图层类型（点线面等）
- name 图层名
- coordinateSystem 坐标系统
- effet 效果配置
- lineStyle 线条样式配置
- zlevel 层级
- symbol 图标
- symbolSize 图标的大小
- label 文字
- tooltip 提示框
- data 数据（不同类型的图层格式不同）

#### 具体图层

- 空图层
- 投递线底线
  - 移动线
  ```javascript
    effect: {
      show: true,  
      period: 6,  
      trailLength: 0.7,  
      color: "#ffffff",  
      symbolSize: 3  
    }
  ```
- 投递动效
  - 小飞机图标
    
    ```javascript
      // svgPath
      const applySymbolImg = 
        "image://data:image/png;base64,,
        iVBORw0KGgoAAAANSUhEUgAAAFAAAABQC····rkJggg=="
      
      effect.symbol: applySymbolImg
    ```
- 热点城市
  - 城市图标大小和热度的关系
  ```javascript
    symbolSize: function(val) {
      return val[2];
    }
  ```
  - 提示框
  ```javascript
    tooltip: {
      formatter({ name, data }) {
        console.log({ data });
        return `<span>${name}</span>
        投递量：<span>${data.rawValue}</span>`;
      }
    }
  ```
  - 波纹效果
  ```
    effectType: 'ripple'
  ```


总配置参数：
```javascript
let series = []
series.push(
  // 空图层
  {
    name: "blank",
    type: "lines",
    zlevel: 1
  },
  // 投递线底线
  {
    name: "applyLine",
    type: "lines",
    zlevel: 2,
    coordinateSystem: "bmap",
    effect: {
      show: true,
      period: 6,
      trailLength: 0.7,
      color: "#ffffff",
      symbolSize: 3
    },
    animation: false,
    lineStyle: {
      normal: {
        color: "#a6c84c",
        width: 0,
        curveness: 0.2
      }
    },
    data: []
  },
  // 投递动效线
  {
    name: "投递",
    type: "lines",
    zlevel: 3,
    coordinateSystem: "bmap",
    symbol: ["none", "none"],
    symbolSize: 10,
    effect: {
      show: true,
      period: 6,
      trailLength: 0,
      symbol: applySymbolImg,
      symbolSize: 15
    },
    lineStyle: {
      normal: {
        color: "#ffffff",
        width: 1,
        opacity: 0.6,
        curveness: 0.2
      }
    },
    data: []
  },
  // 热点城市
  {
    name: "热点城市",
    type: "effectScatter",
    coordinateSystem: "bmap",
    effectType: "ripple",
    zlevel: 4,
    hoverAnimation: true,
    rippleEffect: {
      brushType: "stroke"
    },
    label: {
      show: true,
      position: "right",
      formatter: "{b}",
      color: "#37a5ec"
    },
    symbol: "circle",
    cursor: "pointer",
    symbolSize: function(val) {
      return val[2];
    },
    itemStyle: {
      color: "#F49845"
    },
    tooltip: {
      formatter({ name, data }) {
        console.log({ data });
        return `<span>${name}</span>
        投递量：<span>${data.rawValue}</span>`;
      }
    },
    data: []
  }
);

const defaultOption = {
  backgroundColor: "#0b274b",
  tooltip: {
    trigger: "item"
  },
  series: [],
  bmap: {
    center: [116.114129, 33.550339],
    zoom: 6,
    roam: true,
    mapStyle: {
      styleJson: [
        {
          featureType: "water",
          elementType: "all",
          stylers: {
            color: "#0a274d"
          }
        },
        ······
      ]
    }
  }
};
```


## 数据获取

#### 3个时间间隔
- 请求数据 & 刷新热门城市图层时间间隔 ：1 分钟
- 刷新投递线时间间隔：20 秒
- 刷新右侧投递信息时间间隔：不定，根据数据多寡算出

#### 热门城市数据
- 列表项：`{amount: 727611, city: "深圳"}`
- 在城市地点和坐标数据中通过城市名搜索其坐标
- 尺寸经过特殊处理  
  maxSize, minSize, maxVal, minVal  
  每一个城市尺寸 `targetSize =  minSize + (targetVal - minVal) * (maxSize - minSize) / (maxVal - minVal) `
- 生成热门城市图层的 data 数据：
  ```javascript
    [
      {
        name: "广州"
        rawValue: 756853
        value: [
          "113.23"
          "23.16"
          15
        ] 
      },
      ...
    ]
  ```

#### 投递线数据
- 列表项
```javascript
  {
    applyer: { avatar: "", city: "杭州", gender: "女", name: "柴雯芝"}
    id: 20287629
    target: { avatar: "", city: "南昌", jobName: "护士", name: "南昌大学附属三三四医院"}
    time: 1565248713000
  }
```
- 根据 city 得到投递两方的城市和坐标

#### 右侧投递信息数据
- 根据之前拿到的投递数据，取出 总数 * 1/(请求频率/刷新频率) 的数据
- 根据这批数据的数量 length，开启一个间隔为 20 * 1000 / length 的定时器
- 每次定时器执行，取出 1 个数据扔进组件中（vue）
- 组件显示数据

#### 其他注意点
- 实时展示的移动动效：用 vue 的 transition 实现
- 右上角的时间：使用和风天气 API
- 如何预防内存泄露？所有的计时器都要注意是否有关闭


## 缺陷和问题
1. 动效线图层不能一个个加，只能全量刷新
2. bmap 对地图要素的控制偏弱
3. 内存问题还未经受过检验
4. 城市数据不全