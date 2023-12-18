const tables = document.querySelectorAll('table:not(.rouge)');

function makeResponsive(tableEl) {
  const headers = [...tableEl.querySelectorAll('thead tr th')].map((el) => el.innerText)
  const rows = [...tableEl.querySelectorAll('tbody tr')]
  rows.forEach((row) => {
    const cols = [...row.querySelectorAll('td')]
    cols.forEach((col, index) => col.dataset.label = headers?.[index] ?? '')
  })
}

tables.forEach((table) => {
  makeResponsive(table)
});