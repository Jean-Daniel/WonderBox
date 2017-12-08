/*
 *  WBTableView.m
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBTableView.h>

@implementation WBTableView

- (id<WBTableViewDelegate>)delegate {
  return (id<WBTableViewDelegate>)[super delegate];
}
- (void)setDelegate:(id<WBTableViewDelegate>)delegate {
  [super setDelegate:delegate];
}

- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)anItem {
  if ([anItem action] == @selector(delete:)) {
    id<WBTableViewDelegate> delegate = self.delegate;
    if (SPXDelegateHandle(delegate, canDeleteSelectionInTableView:))
      return [delegate canDeleteSelectionInTableView:self];
    return [self numberOfSelectedRows] > 0 && SPXDelegateHandle(delegate, deleteSelectionInTableView:);
  } else if ([anItem action] == @selector(selectAll:)) {
    // Disable selectAll: when multi-selection is not allowed
    return [self allowsMultipleSelection] || ([self numberOfSelectedRows] == 0 && [self numberOfRows] > 0);
  }
  return [super validateUserInterfaceItem:anItem];
}

- (void)wb_deleteSelection {
  id<WBTableViewDelegate> delegate = self.delegate;
  if (SPXDelegateHandle(delegate, deleteSelectionInTableView:)) {
    [delegate deleteSelectionInTableView:self];
  } else {
    NSBeep();
  }
}

- (IBAction)delete:(id)sender {
  [self wb_deleteSelection];
}

- (void)keyDown:(NSEvent *)theEvent {
  switch ([theEvent keyCode]) {
    case 0x033: //kVirtualDeleteKey:
    case 0x075: //kVirtualForwardDeleteKey:
      return [self wb_deleteSelection];
    case 0x04C: //kVirtualEnterKey:
    case 0x024: //kVirtualReturnKey:
    {
      id target = [self target];
      SEL doubleAction = [self doubleAction];
      if (doubleAction && [self sendAction:doubleAction to:target])
        return;
    }
      break;
    default: break;
  }
  [super keyDown:theEvent];
}

@end

// MARK: -
@implementation WBOutlineView

#pragma mark -
- (id<WBOutlineViewDelegate>)delegate {
  return (id<WBOutlineViewDelegate>)[super delegate];
}
- (void)setDelegate:(id<WBOutlineViewDelegate>)aDelegate {
  [super setDelegate:aDelegate];
}

- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)anItem {
  if ([anItem action] == @selector(delete:)) {
    id<WBOutlineViewDelegate> delegate = self.delegate;
    if (SPXDelegateHandle(delegate, canDeleteSelectionInOutlineView:))
      return [delegate canDeleteSelectionInOutlineView:self];
    return [self numberOfSelectedRows] != 0 && SPXDelegateHandle(delegate, deleteSelectionInOutlineView:);
  } else if ([anItem action] == @selector(selectAll:)) {
    // Disable selectAll: when multi-selection is not allowed
    return [self allowsMultipleSelection] || ([self numberOfSelectedRows] == 0 && [self numberOfRows] > 0);
  }

  return [super validateUserInterfaceItem:anItem];
}

- (void)wb_deleteSelection {
  id<WBOutlineViewDelegate> delegate = self.delegate;
  if (SPXDelegateHandle(delegate, deleteSelectionInOutlineView:)) {
    [delegate deleteSelectionInOutlineView:self];
  } else {
    NSBeep();
  }
}

- (IBAction)delete:(id)sender {
  [self wb_deleteSelection];
}

- (void)keyDown:(NSEvent *)theEvent {
  switch ([theEvent keyCode]) {
    case 0x033: //kVirtualDeleteKey:
    case 0x075: //kVirtualForwardDeleteKey:
      return [self wb_deleteSelection];
    case 0x04C: //kVirtualEnterKey:
    case 0x024: //kVirtualReturnKey:
    {
      id target = [self target];
      SEL doubleAction = [self doubleAction];
      if (doubleAction && [self sendAction:doubleAction to:target])
        return;
    }
      break;
    default: break;
  }
  [super keyDown:theEvent];
}

@end

