import { graphql, compose, withApollo } from "react-apollo";

import {
  UserRegMutation,
  UserRegMutationVariables,
} from "../../graphql/apollo-types/UserRegMutation";
import {
  REG_USER_MUTATION,
  UserRegMutationFn,
  RegMutationProps,
} from "../../graphql/user-reg.mutation";
import { SignUp as Comp } from "./component";
import { userLocalMutationGql } from "../../state/user.resolver";

const regUserGql = graphql<
  {},
  UserRegMutation,
  UserRegMutationVariables,
  RegMutationProps
>(REG_USER_MUTATION, {
  props: props => {
    const mutate = props.mutate as UserRegMutationFn;

    return {
      regUser: mutate,
    };
  },
});

export const SignUp = compose(
  withApollo,
  userLocalMutationGql,
  regUserGql,
)(Comp);
