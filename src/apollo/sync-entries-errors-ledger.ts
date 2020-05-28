/* istanbul ignore file */
import gql from "graphql-tag";
import { ENTRIES_SYNC_ERRORS_LEDGER_CACHE_KEY } from "./resolvers";
import {UnsyncableEntriesErrors} from "../utils/unsynced-ledger.types";

const QUERY = gql`
  query {
    entriesSyncErrorsLedger @client
  }
`;

export function getSyncEntriesErrorsFromLedger(clientId: string) {
  return getSyncEntriesErrorsLedger()[clientId];
}

export function removeSyncEntriesErrorsFromLedger(ids: string[]) {
  const ledger = getSyncEntriesErrorsLedger();

  ids.forEach((id) => {
    delete ledger[id];
  });

  writeSyncEntriesErrorsLedger(ledger);
}

export function writeSyncEntriesErrorsLedger(
  newLedgerItems: UnsyncableEntriesErrors = {},
) {
  const { cache } = window.____ebnis;
  const ledger = { ...getSyncEntriesErrorsLedger(), ...newLedgerItems };

  cache.writeData({
    data: {
      [ENTRIES_SYNC_ERRORS_LEDGER_CACHE_KEY]: JSON.stringify(ledger),
    },
  });
}

export function getSyncEntriesErrorsLedger(): UnsyncableEntriesErrors {
  const { cache } = window.____ebnis;

  try {
    const data = cache.readQuery<QueryResult>({
      query: QUERY,
    });

    const ledger = data && data[ENTRIES_SYNC_ERRORS_LEDGER_CACHE_KEY];

    return ledger ? JSON.parse(ledger) : {};
  } catch (error) {
    if (error.message.includes(ENTRIES_SYNC_ERRORS_LEDGER_CACHE_KEY)) {
      return {} as UnsyncableEntriesErrors;
    }

    throw error;
  }
}

interface QueryResult {
  entriesSyncErrorsLedger: string;
}
