import { Reducer, Dispatch, PropsWithChildren } from "react";
import { wrapReducer } from "../../logger";
import immer, { Draft } from "immer";
import { StateValue } from "../../utils/types";
import {
  BChannel,
  BroadcastMessageConnectionChangedPayload,
} from "../../utils/types";
import { MY_URL } from "../../utils/urls";
import {
  getLocation,
  windowChangeUrl,
  ChangeUrlType,
} from "../../utils/global-window";
import {
  OnExperiencesDeletedSubscription,
  OnExperiencesDeletedSubscription_onExperiencesDeleted_experiences,
} from "../../graphql/apollo-types/OnExperiencesDeletedSubscription";
import {
  GenericGeneralEffect,
  getGeneralEffects,
  GenericEffectDefinition,
} from "../../utils/effects";
import {
  purgeExperiencesFromCache1,
  purgeEntry,
} from "../../apollo/update-get-experiences-mini-query";
import { syncToServer } from "../../apollo/sync-to-server";
import {
  OnSyncedData,
  OfflineIdToOnlineExperienceMap,
  OnlineExperienceIdToOfflineEntriesMap,
} from "../../utils/sync-to-server.types";
import { WithSubscriptionContextProps } from "../../utils/app-context";
import { readEntryFragment } from "../../apollo/get-detailed-experience-query";
import { EntryFragment } from "../../graphql/apollo-types/EntryFragment";

export enum ActionType {
  CONNECTION_CHANGED = "@with-subscription/connection-changed",
  EXPERIENCE_DELETED = "@with-subscription/experience-deleted",
  ON_SYNC = "@with-subscription/on-sync",
}

export const reducer: Reducer<StateMachine, Action> = (state, action) =>
  wrapReducer(
    state,
    action,
    (prevState, { type, ...payload }) => {
      return immer(prevState, (proxy) => {
        proxy.effects.general.value = StateValue.noEffect;
        delete proxy.effects.general[StateValue.hasEffects];

        switch (type) {
          case ActionType.CONNECTION_CHANGED:
            handleConnectionChangedAction(
              proxy,
              payload as BroadcastMessageConnectionChangedPayload,
            );
            break;

          case ActionType.EXPERIENCE_DELETED:
            handleExperienceDeletedAction(
              proxy,
              payload as ExperienceDeletedPayload,
            );
            break;

          case ActionType.ON_SYNC:
            handleOnSyncAction(proxy, payload as OnSycPayload);
            break;
        }
      });
    },
    // true,
  );

////////////////////////// STATE UPDATE SECTION ////////////////////////////

export function initState(): StateMachine {
  return {
    effects: {
      general: {
        value: StateValue.noEffect,
      },
    },
    context: {
      connected: null,
    },
  };
}

function handleExperienceDeletedAction(
  proxy: DraftState,
  payload: ExperienceDeletedPayload,
) {
  const { data } = payload;

  // istanbul ignore else:
  if (data) {
    const effects = getGeneralEffects<EffectType, DraftState>(proxy);
    effects.push({
      key: "onExperiencesDeletedEffect",
      ownArgs: data,
    });
  }
}

function handleConnectionChangedAction(
  proxy: DraftState,
  payload: BroadcastMessageConnectionChangedPayload,
) {
  const { connected } = payload;
  proxy.context.connected = connected;

  const effects = getGeneralEffects<EffectType, DraftState>(proxy);
  effects.push({
    key: "syncToServerEffect",
    ownArgs: {
      connected,
    },
  });
}

function handleOnSyncAction(proxy: DraftState, { data }: OnSycPayload) {
  proxy.context.onSyncData = data;
}

////////////////////////// END STATE UPDATE SECTION //////////////////////

////////////////////////// EFFECTS SECTION ////////////////////////////

const onExperiencesDeletedEffect: DefOnExperiencesDeletedEffect["func"] = async (
  ownArgs,
) => {
  const data = ownArgs.onExperiencesDeleted;

  // istanbul ignore else:
  if (data) {
    const ids = data.experiences.map((experience) => {
      return (experience as OnExperiencesDeletedSubscription_onExperiencesDeleted_experiences)
        .id;
    });

    purgeExperiencesFromCache1(ids);
    const { persistor } = window.____ebnis;
    await persistor.persist();

    // istanbul ignore else:
    if (getLocation().pathname.includes(MY_URL)) {
      windowChangeUrl(MY_URL, ChangeUrlType.replace);
    }
  }
};

type DefOnExperiencesDeletedEffect = EffectDefinition<
  "onExperiencesDeletedEffect",
  OnExperiencesDeletedSubscription
>;

const syncToServerEffect: DefSyncToServerEffect["func"] = (
  { connected },
  _,
) => {
  if (!connected) {
    return;
  }

  setTimeout(() => {
    syncToServer();
  }, 100);
};

type DefSyncToServerEffect = EffectDefinition<
  "syncToServerEffect",
  {
    connected: boolean;
  }
>;

export const effectFunctions = {
  onExperiencesDeletedEffect,
  syncToServerEffect,
};

export async function cleanUpOfflineExperiences(
  data: OfflineIdToOnlineExperienceMap,
) {
  purgeExperiencesFromCache1(Object.keys(data));
  const { persistor } = window.____ebnis;
  await persistor.persist();
}

export async function cleanUpSyncedOfflineEntries(
  data: OnlineExperienceIdToOfflineEntriesMap,
) {
  const { persistor } = window.____ebnis;

  const toPurge = Object.values(data).flatMap((offlineIdToEntryMap) =>
    Object.keys(offlineIdToEntryMap),
  );

  toPurge.forEach((id) => {
    purgeEntry(readEntryFragment(id) as EntryFragment);
  });

  persistor.persist();
}

////////////////////////// END EFFECTS SECTION ////////////////////////////

type DraftState = Draft<StateMachine>;

export type StateMachine = GenericGeneralEffect<EffectType> &
  Readonly<{
    context: Readonly<WithSubscriptionContextProps>;
  }>;

type Action =
  | ({
      type: ActionType.CONNECTION_CHANGED;
    } & BroadcastMessageConnectionChangedPayload)
  | ({
      type: ActionType.EXPERIENCE_DELETED;
    } & ExperienceDeletedPayload)
  | ({
      type: ActionType.ON_SYNC;
    } & OnSycPayload);

export type OnSycPayload = {
  data?: OnSyncedData;
};

interface ExperienceDeletedPayload {
  data?: OnExperiencesDeletedSubscription;
}

export type CallerProps = PropsWithChildren<{
  bc: BChannel;
}>;

export type Props = CallerProps;

export type DispatchType = Dispatch<Action>;

export interface EffectArgs {
  dispatch: DispatchType;
}

type EffectDefinition<
  Key extends keyof typeof effectFunctions,
  OwnArgs = {}
> = GenericEffectDefinition<EffectArgs, CallerProps, Key, OwnArgs>;

type EffectType = DefOnExperiencesDeletedEffect | DefSyncToServerEffect;
