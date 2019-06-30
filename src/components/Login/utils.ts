import * as Yup from "yup";
import { RouteComponentProps } from "@reach/router";
import { Reducer } from "react";
import { FormikErrors } from "formik";
import { ApolloError } from "apollo-client";
import { WithApolloClient } from "react-apollo";
import immer from "immer";
import { LoginUser as FormValues } from "../../graphql/apollo-types/globalTypes";
import { LoginMutationProps } from "../../graphql/login.mutation";
import { PasswordInputAction, PasswordInputType } from "../PwdInput/pwd-input";
import {
  UserLocalMutationProps,
  UserLocalGqlProps,
} from "../../state/user.resolver";

export interface OwnProps
  extends RouteComponentProps<{}>,
    WithApolloClient<{}> {}

export type Props = OwnProps &
  LoginMutationProps &
  UserLocalMutationProps &
  UserLocalGqlProps;

export const ValidationSchema = Yup.object<FormValues>().shape({
  email: Yup.string()
    .email("must be valid email address")
    .required(),
  password: Yup.string()
    .required()
    .min(4, "too short"),
});

export const RouterThings = {
  documentTitle: "Log in",
};

export enum ActionType {
  setOtherErrors = "@components/login/set_other_errors",
  setFormError = "@components/login/set_form_error",
  setServerErrors = "@components/login/set_server_errors",
  clearAllErrors = "@components/login/clear_all_errors",
}

export interface State {
  readonly otherErrors?: string | null;
  readonly formErrors?: FormikErrors<FormValues> | null;
  readonly serverFieldErrors?: string | null;
  readonly pwdType?: "password" | "text";
  readonly networkError?: string | null;
}

export type Action =
  | [ActionType.clearAllErrors]
  | [ActionType.setOtherErrors, string]
  | [ActionType.setFormError, FormikErrors<FormValues>]
  | [ActionType.setServerErrors, string]
  | PasswordInputAction;

export const initialState = {} as State;

export const reducer: Reducer<State, Action> = (prevState, [type, payload]) => {
  return immer(prevState, proxy => {
    switch (type) {
      case ActionType.setOtherErrors:
        {
          proxy.otherErrors = payload as string;
        }

        break;

      case ActionType.setFormError:
        {
          proxy.formErrors = payload as FormikErrors<FormValues>;
        }

        break;

      case ActionType.setServerErrors:
        {
          const { graphQLErrors, networkError } = payload as ApolloError;

          let error = null;

          if (graphQLErrors && graphQLErrors[0]) {
            error = JSON.parse(graphQLErrors[0].message).error;
          }

          proxy.serverFieldErrors = error;
          proxy.networkError = networkError ? networkError.message : null;
        }

        break;

      case ActionType.clearAllErrors:
        {
          proxy.otherErrors = null;
          proxy.serverFieldErrors = null;
          proxy.formErrors = null;
          proxy.networkError = null;
        }

        break;

      case PasswordInputType:
        {
          proxy.pwdType = payload as "password" | "text";
        }

        break;
    }
  });
};
