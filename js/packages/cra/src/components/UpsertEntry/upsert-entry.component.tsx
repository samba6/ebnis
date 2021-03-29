import { DataDefinitionFragment } from "@eb/cm/src/graphql/apollo-types/DataDefinitionFragment";
import { DataTypes } from "@eb/cm/src/graphql/apollo-types/globalTypes";
import { trimClass } from "@eb/cm/src/utils";
import { StateValue } from "@eb/cm/src/utils/types";
import React, { ChangeEvent, FormEvent, useCallback, useReducer } from "react";
import { useRunEffects } from "../../utils/use-run-effects";
import { errorClassName } from "../../utils/utils.dom";
import { noTriggerDocumentEventClassName } from "../DetailExperience/detail-experience.dom";
import FormCtrlError from "../FormCtrlError/form-ctrl-error.component";
import Loading from "../Loading/loading.component";
import { componentFromDataType } from "./component-from-data-type";
import {
  fieldErrorSelector,
  notificationCloseId,
  submitBtnDomId,
  domPrefix,
} from "./upsert-entry.dom";
import "./upsert-entry.styles.scss";
import {
  ActionType,
  CallerProps,
  DispatchType,
  effectFunctions,
  FieldState,
  FormObjVal,
  initState,
  Props,
  reducer,
  Submission,
} from "./upsert-entry.utils";

export function UpsertEntry(props: Props) {
  const { experience, onClose, className = "" } = props;

  const [stateMachine, dispatch] = useReducer(reducer, props, initState);

  const {
    states: { submission: submissionState, form },
    effects: { general: generalEffects },
  } = stateMachine;

  useRunEffects(generalEffects, effectFunctions, props, { dispatch });

  const onSubmit = useCallback((e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    dispatch({
      type: ActionType.submit,
    });
  }, []);

  const onCloseNotification = useCallback(() => {
    dispatch({
      type: ActionType.dismiss_notification,
    });
  }, []);

  const { dataDefinitions, title } = experience;

  return (
    <>
      <form
        id={domPrefix}
        className={trimClass(`
          modal
          is-active
          component-upsert-entry
          ${submissionState.value === StateValue.active ? "submitting" : ""},
          ${className}
          ${noTriggerDocumentEventClassName}
        `)}
        onSubmit={onSubmit}
      >
        <div className="modal-background"></div>

        <div className="modal-card">
          <header className="modal-card-head">
            <div className="modal-card-title">
              <strong>New Entry</strong>
              <div className="experience-title">{title}</div>
            </div>

            <button
              className="delete upsert-entry__delete"
              aria-label="close"
              type="button"
              onClick={onClose}
            ></button>
          </header>

          <div className="modal-card-body">
            <span className="modal-scroll-into-view" />

            <NotificationComponent
              submissionState={submissionState}
              onCloseNotification={onCloseNotification}
            />

            {dataDefinitions.map((obj, index) => {
              const definition = obj as DataDefinitionFragment;

              return (
                <DataComponent
                  key={definition.id}
                  definition={definition}
                  index={index}
                  fieldState={form.fields[index]}
                  dispatch={dispatch}
                />
              );
            })}
          </div>

          <footer className="modal-card-foot">
            <button
              className="button submit-btn"
              id={submitBtnDomId}
              type="submit"
            >
              Submit
            </button>
          </footer>
        </div>
      </form>

      {submissionState.value === StateValue.active && <Loading />}
    </>
  );
}

const DataComponent = React.memo(
  function DataComponentFn(props: DataComponentProps) {
    const {
      definition,
      index,
      dispatch,
      fieldState: {
        context: { value: currentValue, errors },
      },
    } = props;

    const { name: fieldTitle, type, id } = definition;

    const generic = {
      id,
      name: id,
      value: currentValue,
      onChange:
        type === DataTypes.DATE || type === DataTypes.DATETIME
          ? makeDateChangedFn(dispatch, index)
          : (e: ChangeEvent<HTMLInputElement>) => {
              const value = e.currentTarget.value;

              dispatch({
                type: ActionType.on_form_field_changed,
                fieldIndex: index,
                value,
              });
            },
    };

    const component = componentFromDataType(type, generic);

    return (
      <div
        className={trimClass(`
          ${(!!errors && "error") || ""}
          field
        `)}
      >
        <label
          className="label form__label"
          htmlFor={id}
        >{`[${type}] ${fieldTitle}`}</label>

        <div className="control">{component}</div>

        {errors && (
          <FormCtrlError className={fieldErrorSelector}>
            {errors.map(([k, v]) => {
              return (
                <div key={k}>
                  <span
                    style={{
                      fontWeight: 700,
                    }}
                  >
                    {k}:
                  </span>{" "}
                  <span>{v}</span>
                </div>
              );
            })}
          </FormCtrlError>
        )}
      </div>
    );
  },

  function DataComponentDiff(prevProps, nextProps) {
    return prevProps.fieldState === nextProps.fieldState;
  },
);

function NotificationComponent({
  submissionState,
  onCloseNotification,
}: {
  submissionState: Submission;
  onCloseNotification: () => void;
}) {
  const errorNode =
    submissionState.value === StateValue.errors &&
    submissionState.errors.context.errors;

  if (!errorNode) {
    return null;
  }

  return (
    <div
      className={trimClass(`
        notification
        ${errorClassName}
      `)}
    >
      <button
        id={notificationCloseId}
        type="button"
        className="delete"
        onClick={onCloseNotification}
      />
      <div>
        <strong>
          <p>
            Following errors were received while trying to create/Update the
            entry
          </p>
        </strong>
      </div>
      <hr />
      {errorNode}
    </div>
  );
}

function makeDateChangedFn(dispatch: DispatchType, index: number) {
  return function makeDateChangedFnInner(
    _fieldName: string,
    value: FormObjVal,
  ) {
    dispatch({
      type: ActionType.on_form_field_changed,
      fieldIndex: index,
      value,
    });
  };
}

// istanbul ignore next:
export default (props: CallerProps) => {
  return <UpsertEntry {...props} />;
};

interface DataComponentProps {
  definition: DataDefinitionFragment;
  index: number;
  fieldState: FieldState;
  dispatch: DispatchType;
}
