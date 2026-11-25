// 设计令牌：把原网页 Tailwind 配色与图标映射成小程序可用数据。
// 图标使用 images/ 下由原版 SVG 生成的图片文件。

const INDEX_STYLES = {
  bmi:             { color: "#7c3aed", bg: "#ede9fe", icon: "/images/bmi.svg" },
  bmr:             { color: "#ea580c", bg: "#ffedd5", icon: "/images/bmr.svg" },
  navy:            { color: "#0284c7", bg: "#e0f2fe", icon: "/images/navy.svg" },
  rfm:             { color: "#0e7490", bg: "#cffafe", icon: "/images/rfm.svg" },
  whtr:            { color: "#d97706", bg: "#fef3c7", icon: "/images/whtr.svg" },
  whr:             { color: "#e11d48", bg: "#ffe4e6", icon: "/images/whr.svg" },
  central_obesity: { color: "#ea580c", bg: "#ffedd5", icon: "/images/central_obesity.svg" },
  cardio:          { color: "#dc2626", bg: "#fee2e2", icon: "/images/cardio.svg" }
};

const METRIC_STYLES = {
  weight:             { color: "#7c3aed", bg: "#ede9fe", icon: "/images/weight.svg" },
  height:             { color: "#0284c7", bg: "#e0f2fe", icon: "/images/height.svg" },
  waist:              { color: "#d97706", bg: "#fef3c7", icon: "/images/waist.svg" },
  hip:                { color: "#e11d48", bg: "#ffe4e6", icon: "/images/hip.svg" },
  neck:               { color: "#0d9488", bg: "#ccfbf1", icon: "/images/neck.svg" },
  blood_pressure:     { color: "#dc2626", bg: "#fee2e2", icon: "/images/blood_pressure.svg" },
  resting_heart_rate: { color: "#db2777", bg: "#fce7f3", icon: "/images/resting_heart_rate.svg" }
};

// 状态药丸（记录页）
const STATUS_PILLS = {
  due:     { text: "该测了",   bg: "#22c55e", color: "#fff" },
  overdue: { text: "已逾期",   bg: "#fbbf24", color: "#451a03" },
  early:   { text: "未到下次", bg: "#ede9fe", color: "#6d28d9" },
  settled: { text: "无需更新", bg: "#f5f5f4", color: "#57534e" },
  never:   { text: "未点亮",   bg: "#e7e5e4", color: "#57534e" }
};

// 偏离色带：0 浅紫 → 0.5 琥珀 → 1 浅红 → 1.5 深红 → 2 更深红
const STOPS = [
  [ 0.0, [ 139, 124, 199 ] ],
  [ 0.5, [ 217, 119, 6 ] ],
  [ 1.0, [ 220, 90, 90 ] ],
  [ 1.5, [ 153, 27, 27 ] ],
  [ 2.0, [ 127, 29, 29 ] ]
];

function deviationColor(deviation) {
  if (deviation === null || deviation === undefined) return null;
  const v = Math.max(0, Math.min(2, Number(deviation) || 0));
  for (let i = 0; i < STOPS.length - 1; i++) {
    const a = STOPS[i], b = STOPS[i + 1];
    if (v <= b[0]) {
      const span = b[0] - a[0];
      const ratio = span === 0 ? 0 : (v - a[0]) / span;
      const rgb = a[1].map((from, j) => Math.round(from + (b[1][j] - from) * ratio));
      return "rgb(" + rgb.join(",") + ")";
    }
  }
  return "rgb(127,29,29)";
}

function deviationWord(deviation) {
  if (deviation === null || deviation === undefined) return "";
  if (deviation <= 0) return "健康区";
  if (deviation < 1) return "需留意";
  return "警告";
}

module.exports = {
  INDEX_STYLES: INDEX_STYLES,
  METRIC_STYLES: METRIC_STYLES,
  STATUS_PILLS: STATUS_PILLS,
  deviationColor: deviationColor,
  deviationWord: deviationWord
};
