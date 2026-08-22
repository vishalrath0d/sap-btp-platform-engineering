'use strict';

/**
 * Generates human-readable document numbers (PR-00001, PO-00001) by
 * counting existing rows. Good enough for a single-writer local/demo
 * setup; NOT safe under concurrent writers (two simultaneous submits could
 * race to the same number). Documented honestly in the service README
 * rather than silently pretending this is production-hardened — a real
 * deployment would use a DB sequence or the CAP `@cds.autoexpose`/UUID
 * pattern for the number generator, not a count(*).
 */
async function nextNumber(entity, prefix) {
  const { count } = await SELECT.one.from(entity).columns('count(*) as count');
  return `${prefix}-${String((count || 0) + 1).padStart(5, '0')}`;
}

module.exports = { nextNumber };
