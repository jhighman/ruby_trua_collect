import React from 'react';
import { cn } from '../../lib/utils';
import { Button } from './button';
import { Card } from './card';

const Timeline = React.forwardRef(({ className, children, ...props }, ref) => {
  return (
    <div
      ref={ref}
      className={cn('space-y-4', className)}
      {...props}
    >
      {children}
    </div>
  );
});
Timeline.displayName = 'Timeline';

const TimelineItem = React.forwardRef(({ className, children, ...props }, ref) => {
  return (
    <div
      ref={ref}
      className={cn('relative pl-6 pb-6 last:pb-0', className)}
      {...props}
    >
      <div className="absolute left-0 top-0 bottom-0 w-px bg-border" />
      <div className="absolute left-0 top-2 w-2 h-2 rounded-full bg-primary -translate-x-1/2" />
      {children}
    </div>
  );
});
TimelineItem.displayName = 'TimelineItem';

const TimelineItemContent = React.forwardRef(({ className, children, ...props }, ref) => {
  return (
    <div
      ref={ref}
      className={cn('ml-4', className)}
      {...props}
    >
      {children}
    </div>
  );
});
TimelineItemContent.displayName = 'TimelineItemContent';

const TimelineItemHeader = React.forwardRef(({ className, children, ...props }, ref) => {
  return (
    <div
      ref={ref}
      className={cn('flex items-center justify-between mb-2', className)}
      {...props}
    >
      {children}
    </div>
  );
});
TimelineItemHeader.displayName = 'TimelineItemHeader';

const TimelineItemTitle = React.forwardRef(({ className, children, ...props }, ref) => {
  return (
    <h4
      ref={ref}
      className={cn('text-base font-medium', className)}
      {...props}
    >
      {children}
    </h4>
  );
});
TimelineItemTitle.displayName = 'TimelineItemTitle';

const TimelineItemDate = React.forwardRef(({ className, startDate, endDate, isCurrent, ...props }, ref) => {
  const formatDate = (dateString) => {
    if (!dateString) return '';
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', { month: 'short', year: 'numeric' });
  };

  return (
    <div
      ref={ref}
      className={cn('text-sm text-muted-foreground', className)}
      {...props}
    >
      {formatDate(startDate)} - {isCurrent ? 'Present' : formatDate(endDate)}
    </div>
  );
});
TimelineItemDate.displayName = 'TimelineItemDate';

const TimelineItemBody = React.forwardRef(({ className, children, ...props }, ref) => {
  return (
    <div
      ref={ref}
      className={cn('text-sm', className)}
      {...props}
    >
      {children}
    </div>
  );
});
TimelineItemBody.displayName = 'TimelineItemBody';

const TimelineItemActions = React.forwardRef(({ className, children, ...props }, ref) => {
  return (
    <div
      ref={ref}
      className={cn('flex items-center space-x-2 mt-2', className)}
      {...props}
    >
      {children}
    </div>
  );
});
TimelineItemActions.displayName = 'TimelineItemActions';

const TimelineAccumulator = React.forwardRef(({
  className,
  items = [],
  renderItem,
  onAdd,
  onEdit,
  onRemove,
  addButtonText = 'Add Entry',
  emptyText = 'No entries yet. Click the button below to add one.',
  ...props
}, ref) => {
  return (
    <div
      ref={ref}
      className={cn('space-y-4', className)}
      {...props}
    >
      {items.length > 0 ? (
        <Timeline>
          {items.map((item, index) => (
            <TimelineItem key={index}>
              {renderItem ? (
                renderItem(item, index, { onEdit, onRemove })
              ) : (
                <Card className="p-4">
                  <TimelineItemHeader>
                    <TimelineItemTitle>{item.title || `Entry ${index + 1}`}</TimelineItemTitle>
                    <TimelineItemDate
                      startDate={item.start_date}
                      endDate={item.end_date}
                      isCurrent={item.is_current}
                    />
                  </TimelineItemHeader>
                  <TimelineItemBody>
                    {item.description || 'No description provided.'}
                  </TimelineItemBody>
                  {(onEdit || onRemove) && (
                    <TimelineItemActions>
                      {onEdit && (
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => onEdit(item, index)}
                        >
                          Edit
                        </Button>
                      )}
                      {onRemove && (
                        <Button
                          variant="destructive"
                          size="sm"
                          onClick={() => onRemove(item, index)}
                        >
                          Remove
                        </Button>
                      )}
                    </TimelineItemActions>
                  )}
                </Card>
              )}
            </TimelineItem>
          ))}
        </Timeline>
      ) : (
        <div className="text-center py-8 text-muted-foreground">
          {emptyText}
        </div>
      )}
      {onAdd && (
        <div className="flex justify-center">
          <Button onClick={onAdd}>
            {addButtonText}
          </Button>
        </div>
      )}
    </div>
  );
});
TimelineAccumulator.displayName = 'TimelineAccumulator';

export {
  Timeline,
  TimelineItem,
  TimelineItemContent,
  TimelineItemHeader,
  TimelineItemTitle,
  TimelineItemDate,
  TimelineItemBody,
  TimelineItemActions,
  TimelineAccumulator,
};