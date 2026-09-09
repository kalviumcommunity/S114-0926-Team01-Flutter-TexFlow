const { body } = require('express-validator');

const createLogValidation = [
  body('stageId').notEmpty().withMessage('Stage is required'),
  body('quantity').isInt({ min: 1 }).withMessage('Quantity must be a positive integer'),
  body('unit').optional().isIn(['meters', 'kg', 'pieces']).withMessage('Invalid unit'),
  body('shift').isIn(['morning', 'afternoon', 'night']).withMessage('Shift must be morning, afternoon, or night'),
  body('notes').optional().trim(),
];

module.exports = { createLogValidation };
