const DATE_ONLY_PATTERN = /^\d{4}-\d{2}-\d{2}$/;

const SHANGHAI_DATE_FORMATTER = new Intl.DateTimeFormat('en-US', {
  timeZone: 'Asia/Shanghai',
  year: 'numeric',
  month: '2-digit',
  day: '2-digit',
});

export function formatDate(value) {
  if (!value) return '';

  const text = String(value);
  if (DATE_ONLY_PATTERN.test(text)) return text;

  const date = new Date(text);
  if (Number.isNaN(date.getTime())) return text;

  const values = Object.fromEntries(
    SHANGHAI_DATE_FORMATTER
      .formatToParts(date)
      .filter(part => part.type !== 'literal')
      .map(part => [part.type, part.value])
  );

  return `${values.year}-${values.month}-${values.day}`;
}
