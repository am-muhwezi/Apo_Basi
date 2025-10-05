/**
 * StatusModal Usage Examples
 *
 * This file demonstrates how to use the StatusModal component across the app
 * for various scenarios like bus creation, user creation, etc.
 */

import { useStatusModal } from '../contexts/StatusModalContext';

// Example 1: Bus Creation Success/Failure
export const BusCreationExample = () => {
  const { showSuccess, showError } = useStatusModal();

  const handleCreateBus = async (busData: any) => {
    try {
      // API call to create bus
      const response = await fetch('/api/buses', {
        method: 'POST',
        body: JSON.stringify(busData),
      });

      if (response.ok) {
        showSuccess(
          'Bus Created Successfully',
          'The bus has been added to the system and is ready for assignment.'
        );
      } else {
        throw new Error('Failed to create bus');
      }
    } catch (error) {
      showError(
        'Bus Creation Failed',
        'Unable to create the bus. Please check the details and try again.'
      );
    }
  };
};

// Example 2: Parent Registration Success/Failure
export const ParentRegistrationExample = () => {
  const { showSuccess, showError } = useStatusModal();

  const handleRegisterParent = async (parentData: any) => {
    try {
      const response = await fetch('/api/users/parent', {
        method: 'POST',
        body: JSON.stringify(parentData),
      });

      if (response.ok) {
        showSuccess(
          'Parent Account Created',
          'The parent account has been successfully created and activated.'
        );
      } else {
        throw new Error('Registration failed');
      }
    } catch (error) {
      showError(
        'Registration Failed',
        'Unable to create parent account. The email might already be in use.'
      );
    }
  };
};

// Example 3: Child Registration Success/Failure
export const ChildRegistrationExample = () => {
  const { showSuccess, showError } = useStatusModal();

  const handleAddChild = async (childData: any) => {
    try {
      const response = await fetch('/api/children', {
        method: 'POST',
        body: JSON.stringify(childData),
      });

      if (response.ok) {
        showSuccess(
          'Child Added Successfully',
          'The child has been added to your account and assigned to the bus route.'
        );
      } else {
        throw new Error('Failed to add child');
      }
    } catch (error) {
      showError(
        'Failed to Add Child',
        'Unable to add the child. Please verify the information and try again.'
      );
    }
  };
};

// Example 4: Driver Creation Success/Failure
export const DriverCreationExample = () => {
  const { showSuccess, showError } = useStatusModal();

  const handleCreateDriver = async (driverData: any) => {
    try {
      const response = await fetch('/api/users/driver', {
        method: 'POST',
        body: JSON.stringify(driverData),
      });

      if (response.ok) {
        showSuccess(
          'Driver Account Created',
          'The driver account has been created and is ready for bus assignment.'
        );
      } else {
        throw new Error('Failed to create driver');
      }
    } catch (error) {
      showError(
        'Driver Creation Failed',
        'Unable to create driver account. Please check license details and try again.'
      );
    }
  };
};

// Example 5: Bus Minder/Admin Creation Success/Failure
export const BusMinderCreationExample = () => {
  const { showSuccess, showError } = useStatusModal();

  const handleCreateBusMinder = async (adminData: any) => {
    try {
      const response = await fetch('/api/users/busminder', {
        method: 'POST',
        body: JSON.stringify(adminData),
      });

      if (response.ok) {
        showSuccess(
          'Bus Minder Account Created',
          'The bus minder account has been created with admin privileges.'
        );
      } else {
        throw new Error('Failed to create bus minder');
      }
    } catch (error) {
      showError(
        'Bus Minder Creation Failed',
        'Unable to create bus minder account. Please verify permissions and try again.'
      );
    }
  };
};

// Example 6: Generic Success/Error Usage
export const GenericExample = () => {
  const { showSuccess, showError } = useStatusModal();

  // Show success for any operation
  const handleSuccess = () => {
    showSuccess(
      'Operation Successful',
      'Your action has been completed successfully.'
    );
  };

  // Show error for any operation
  const handleError = () => {
    showError(
      'Operation Failed',
      'An error occurred while processing your request.'
    );
  };
};
