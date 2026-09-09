const formatDate = (date) => {
  return new Date(date).toISOString().split('T')[0];
};

const getShiftTimes = (shift) => {
  const times = {
    morning: { start: 6, end: 14 },
    afternoon: { start: 14, end: 22 },
    night: { start: 22, end: 6 },
  };
  return times[shift];
};

module.exports = { formatDate, getShiftTimes };
