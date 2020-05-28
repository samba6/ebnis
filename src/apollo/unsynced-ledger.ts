/* istanbul ignore file */
import gql from "graphql-tag";
import {
  UnsyncedLedger,
  UnsyncedLedgerItem,
  UnsyncableEntriesErrors,
  UnsyncedModifiedExperience,
} from "../utils/unsynced-ledger.types";

const UNSYNCED_LEDGER_QUERY = gql`
  query {
    unsyncedLedger @client
  }
`;

export function writeUnsyncedExperience(id: string, data: UnsyncedLedgerItem) {
  const unsyncedLedger = getUnsyncedLedger();

  if (Object.keys(data).length) {
    unsyncedLedger[id] = data;
  } else {
    delete unsyncedLedger[id];
  }

  writeUnsyncedLedger(unsyncedLedger);
}

export function getUnsyncedExperience(id: string): UnsyncedLedgerItem | null {
  const unsyncedLedger = getUnsyncedLedger();
  return unsyncedLedger[id] || null;
}

export function removeUnsyncedExperience(id: string) {
  const unsyncedLedger = getUnsyncedLedger();
  delete unsyncedLedger[id];
  writeUnsyncedLedger(unsyncedLedger);
}

export function removeUnsyncedExperiences(ids: string[]) {
  const unsyncedLedger = getUnsyncedLedger();

  ids.forEach((id) => {
    delete unsyncedLedger[id];
  });

  writeUnsyncedLedger(unsyncedLedger);
}

function writeUnsyncedLedger(unsyncedLedger: UnsyncedLedger) {
  const { cache } = window.____ebnis;
  cache.writeData({
    data: {
      unsyncedLedger: JSON.stringify(unsyncedLedger),
    },
  });
}

function getUnsyncedLedger() {
  const { cache } = window.____ebnis;
  const data = cache.readQuery<UnsyncedLedgerQueryResult>({
    query: UNSYNCED_LEDGER_QUERY,
  });

  const unsyncedLedger = data && data.unsyncedLedger;

  return unsyncedLedger ? JSON.parse(unsyncedLedger) : {};
}

export function removeSyncEntriesErrorsFromLedger(
  experienceId: string,
  clientIds: string[],
) {
  const entriesErrors = getSyncEntriesErrorsLedger(experienceId);

  if (!entriesErrors) {
    return;
  }

  clientIds.forEach((id) => {
    delete entriesErrors[id];
  });

  writeSyncEntriesErrorsLedger(experienceId, entriesErrors);
}

export function writeSyncEntriesErrorsLedger(
  experienceId: string,
  newLedgerItems: UnsyncableEntriesErrors = {},
) {
  const unsyncedExperience = (getUnsyncedExperience(experienceId) ||
    {}) as UnsyncedModifiedExperience;

  let entriesErrors = (unsyncedExperience.entriesErrors ||
    {}) as UnsyncableEntriesErrors;

  entriesErrors = { ...entriesErrors, ...newLedgerItems };

  if (Object.keys(entriesErrors).length) {
    unsyncedExperience.entriesErrors = entriesErrors;
    unsyncedExperience.newEntries = true;
  } else {
    delete unsyncedExperience.entriesErrors;
  }

  writeUnsyncedExperience(experienceId, unsyncedExperience);
}

export function getSyncEntriesErrorsLedger(
  experienceId: string,
): UnsyncableEntriesErrors | null {
  const unsyncedExperience = (getUnsyncedExperience(experienceId) ||
    {}) as UnsyncedModifiedExperience;

  return unsyncedExperience.entriesErrors || null;
}

interface UnsyncedLedgerQueryResult {
  unsyncedLedger: string; // UnsyncedLedger;
}
