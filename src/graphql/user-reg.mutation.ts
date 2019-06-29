import gql from "graphql-tag";
import { MutationFn } from "react-apollo";

import userFragment from "./user.fragment";
import {
  UserRegMutation,
  UserRegMutationVariables,
} from "./apollo-types/UserRegMutation";

export const REG_USER_MUTATION = gql`
  mutation UserRegMutation($registration: Registration!) {
    registration(registration: $registration) {
      ...UserFragment
    }
  }
  ${userFragment}
`;

export type UserRegMutationFn = MutationFn<
  UserRegMutation,
  UserRegMutationVariables
>;

export interface RegMutationProps {
  regUser?: UserRegMutationFn;
}
