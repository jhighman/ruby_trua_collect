import React from 'react';
import { Slot } from '@radix-ui/react-slot';
import { Controller, FormProvider, useFormContext } from 'react-hook-form';
import { cn } from '../../lib/utils';
import { Label } from './label';

const Form = FormProvider;

const FormField = ({ name, ...props }) => {
  const { control } = useFormContext();

  return (
    <Controller
      name={name}
      control={control}
      render={({ field, fieldState }) => (
        <FormItem>
          <FormControl>
            <Slot
              {...field}
              {...props}
              className={cn(
                props.className,
                fieldState.error && 'border-destructive'
              )}
            />
          </FormControl>
          {fieldState.error?.message && (
            <FormMessage>{fieldState.error.message}</FormMessage>
          )}
        </FormItem>
      )}
    />
  );
};

const FormItem = React.forwardRef(({ className, ...props }, ref) => {
  return (
    <div
      ref={ref}
      className={cn('space-y-2', className)}
      {...props}
    />
  );
});
FormItem.displayName = 'FormItem';

const FormLabel = React.forwardRef(({ className, ...props }, ref) => {
  return (
    <Label
      ref={ref}
      className={cn('block text-sm font-medium', className)}
      {...props}
    />
  );
});
FormLabel.displayName = 'FormLabel';

const FormControl = React.forwardRef(({ ...props }, ref) => {
  return <Slot ref={ref} {...props} />;
});
FormControl.displayName = 'FormControl';

const FormDescription = React.forwardRef(({ className, ...props }, ref) => {
  return (
    <p
      ref={ref}
      className={cn('text-sm text-muted-foreground', className)}
      {...props}
    />
  );
});
FormDescription.displayName = 'FormDescription';

const FormMessage = React.forwardRef(({ className, children, ...props }, ref) => {
  return (
    <p
      ref={ref}
      className={cn('text-sm font-medium text-destructive', className)}
      {...props}
    >
      {children}
    </p>
  );
});
FormMessage.displayName = 'FormMessage';

const FormSection = React.forwardRef(({ className, title, description, children, ...props }, ref) => {
  return (
    <div
      ref={ref}
      className={cn('space-y-4 rounded-lg border p-4', className)}
      {...props}
    >
      {title && (
        <div className="space-y-1">
          <h3 className="text-lg font-medium">{title}</h3>
          {description && (
            <p className="text-sm text-muted-foreground">{description}</p>
          )}
        </div>
      )}
      <div className="space-y-4">
        {children}
      </div>
    </div>
  );
});
FormSection.displayName = 'FormSection';

const FormActions = React.forwardRef(({ className, ...props }, ref) => {
  return (
    <div
      ref={ref}
      className={cn('flex items-center justify-end space-x-2 pt-4', className)}
      {...props}
    />
  );
});
FormActions.displayName = 'FormActions';

export {
  Form,
  FormField,
  FormItem,
  FormLabel,
  FormControl,
  FormDescription,
  FormMessage,
  FormSection,
  FormActions,
};