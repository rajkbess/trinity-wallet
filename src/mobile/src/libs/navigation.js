import last from 'lodash/last';
import { Navigation } from 'react-native-navigation';
import timer from 'react-native-timer';
import { ActionTypes } from 'shared-modules/actions/wallet';
import store from '../../../shared/store';

export const navigator = {
    push: (nextScreen, options, delay = 300) => {
        const currentScreen = last(store.getState().ui.navStack);
        store.dispatch({ type: ActionTypes.PUSH_ROUTE, payload: nextScreen });
        return timer.setTimeout(
            currentScreen,
            () =>
                Navigation.push('appStack', {
                    component: {
                        name: nextScreen,
                        options,
                    },
                }),
            delay,
        );
    },
    pop: (componentId, delay = 300) => {
        const currentScreen = last(store.getState().ui.navStack);
        store.dispatch({ type: ActionTypes.POP_ROUTE });
        return timer.setTimeout(currentScreen, () => Navigation.pop(componentId), delay);
    },
    setStackRoot: (nextScreen, options, delay = 300) => {
        const currentScreen = last(store.getState().ui.navStack);
        store.dispatch({ type: ActionTypes.RESET_ROUTE, payload: nextScreen });
        return timer.setTimeout(
            currentScreen,
            () =>
                Navigation.setStackRoot('appStack', {
                    component: {
                        name: nextScreen,
                        options,
                    },
                }),
            delay,
        );
    },
};
