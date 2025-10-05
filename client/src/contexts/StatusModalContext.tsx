import React, { createContext, useContext, useState, useCallback } from 'react';
import StatusModal, { StatusModalType } from '../components/StatusModal';

interface StatusModalContextType {
  showSuccess: (title: string, message: string) => void;
  showError: (title: string, message: string) => void;
  hideModal: () => void;
}

interface StatusModalState {
  visible: boolean;
  type: StatusModalType;
  title: string;
  message: string;
}

const StatusModalContext = createContext<StatusModalContextType | undefined>(undefined);

export const StatusModalProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [modalState, setModalState] = useState<StatusModalState>({
    visible: false,
    type: 'success',
    title: '',
    message: '',
  });

  const showSuccess = useCallback((title: string, message: string) => {
    setModalState({
      visible: true,
      type: 'success',
      title,
      message,
    });
  }, []);

  const showError = useCallback((title: string, message: string) => {
    setModalState({
      visible: true,
      type: 'error',
      title,
      message,
    });
  }, []);

  const hideModal = useCallback(() => {
    setModalState((prev) => ({ ...prev, visible: false }));
  }, []);

  return (
    <StatusModalContext.Provider value={{ showSuccess, showError, hideModal }}>
      {children}
      <StatusModal
        visible={modalState.visible}
        type={modalState.type}
        title={modalState.title}
        message={modalState.message}
        onClose={hideModal}
      />
    </StatusModalContext.Provider>
  );
};

export const useStatusModal = (): StatusModalContextType => {
  const context = useContext(StatusModalContext);
  if (!context) {
    throw new Error('useStatusModal must be used within a StatusModalProvider');
  }
  return context;
};
