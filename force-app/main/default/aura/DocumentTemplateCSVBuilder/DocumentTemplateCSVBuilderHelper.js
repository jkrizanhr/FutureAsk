({
    /* NOTES:
        Object.assign is frequently used to copy an object's attributes
        without copying any references. In doing so, we can modify this copied object
        without having the changes reflected on the original object.
    */

    addNewSubcolumn: function(component, column) {
        var groupingValue = '0';
        if (column.subColumns[column.subColumns.length-1].groupingValue) {
            groupingValue = column.subColumns[column.subColumns.length-1].groupingValue;
        }
        var newSubColumn = {
            index: column.subColumns.length+1,
            parentIndex: column.index,
            parentKey: column.subColumns[column.subColumns.length-1].parentKey,
            columnNum: column.subColumns[column.subColumns.length-1].columnNum+1,
            numResults: '',
            selectIndex: column.subColumns[column.subColumns.length-1].selectIndex,
            altValue: '',
            apiName: '',
            field: '--SELECT--',
            formatting: '',
            groupingValue: groupingValue,
            key: '',
            label: '',
            queryId: column.queryId,
            selectSource: column.subColumns[column.subColumns.length-1].selectSource,
            subColumns: []
        };
        var newColumnGrouping = JSON.parse(JSON.stringify(column));
        newColumnGrouping.subColumns.push(newSubColumn);
        var csvColumnConfig = component.get('v.csvColumnConfig');
        Object.assign(csvColumnConfig[newColumnGrouping.index], newColumnGrouping);
        this._updateIndices(component, csvColumnConfig, column.index, column.columnNum);
    },

    /*
        Add a new top-level column to the end of the table
    */
    addColumn: function(component) {
        var csvColumnConfig = component.get('v.csvColumnConfig');
        var lastIndex = 0;
        var lastColumnNum = 0;
        var index = 0;
        var columnNum = 0;

        if (csvColumnConfig && csvColumnConfig.length > 0) {
            var lastColumn = csvColumnConfig[csvColumnConfig.length-1];
            lastIndex = lastColumn.index;
            lastColumnNum = lastColumn.columnNum;
            index = lastColumn.index + 1;
            columnNum = lastColumn.columnNum + 1;
        }

        var col = {
            index: index,
            parentIndex: null,
            columnNum: columnNum,
            numResults: '',
            selectIndex: 0,
            altValue: '',
            apiName: '',
            field: '--SELECT--',
            formatting: '',
            groupingValue: '',
            key: '',
            label: '',
            queryId: '',
            selectSource: '',
            subColumns: []
        };
        csvColumnConfig.push(col);
        this._updateIndices(component, csvColumnConfig, lastIndex, lastColumnNum);
    },

    removeColumn: function(component, column) {
        var csvColumnConfig = component.get('v.csvColumnConfig');

        if (!column.parentIndex || column.parentIndex === undefined) {
            // Delete the column
            var res = csvColumnConfig.splice(column.index, 1);
            this._updateIndices(component, csvColumnConfig, column.index, column.columnNum);
        } else {
            // Delete the subColumn
            var parentColumnCopy = JSON.parse(JSON.stringify(csvColumnConfig[column.parentIndex]));
            var removedSubCol = csvColumnConfig[column.parentIndex].subColumns.splice(column.index, 1);

            if (parentColumnCopy.subColumns.length === 0) {
               // The only subcolumn config was removed so delete the parent column as well.
               var removedParentCol = csvColumnConfig.splice(column.parentIndex, 1);
            }
            this._updateIndices(component, csvColumnConfig, parentColumnCopy.index, parentColumnCopy.columnNum);
        }
    },

    _moveSubColumn: function(component, column, modifier) {
        var csvColumnConfig = component.get('v.csvColumnConfig');
        var temp = {};
        Object.assign(temp, csvColumnConfig[column.parentIndex].subColumns[column.index]);
        Object.assign(
            csvColumnConfig[column.parentIndex].subColumns[column.index],
            csvColumnConfig[column.parentIndex].subColumns[column.index + modifier]
        );
        Object.assign(
            csvColumnConfig[column.parentIndex].subColumns[column.index + modifier],
            temp
        );
        csvColumnConfig[column.parentIndex].subColumns[column.index].index -= modifier;
        csvColumnConfig[column.parentIndex].subColumns[column.index].columnNum -= modifier;
        csvColumnConfig[column.parentIndex].subColumns[column.index + modifier].index += modifier;
        csvColumnConfig[column.parentIndex].subColumns[column.index + modifier].columnNum += modifier;

        component.set('v.csvColumnConfig', csvColumnConfig);
    },

    // modifier = 1 (move down list and increase index) or -1 (move up list and decrease index)
    moveColumn: function(component, column, modifier) {
//        if (modifier === 1) console.log('Moving column down the list and increasing the index...');
//        if (modifier === -1) console.log('Moving column up list and decreasing the index...');

        var csvColumnConfig = component.get('v.csvColumnConfig');

        if (column.parentIndex) {
            // Move the subColumn
            this._moveSubColumn(component, column, modifier);
        } else {
            // Move the column
            var temp = {};
            Object.assign(temp, csvColumnConfig[column.index]);
            Object.assign(csvColumnConfig[column.index], csvColumnConfig[column.index + modifier]);
            Object.assign(csvColumnConfig[column.index + modifier], temp);

            csvColumnConfig[column.index + modifier].index += modifier;
            csvColumnConfig[column.index].index -= modifier;

            // NOTE: The columns have already been swapped so the index in the array has been swapped as well.
            // Now we just need to update the index, parentIndex, and columnNum properities.
            if (csvColumnConfig[column.index + modifier].subColumns.length === 0 && csvColumnConfig[column.index].subColumns.length > 0) {
                /* Swap Primary field with Subquery/Aggregate group */
                this._swapPrimaryFieldWithFieldGroup(component, column, modifier, csvColumnConfig);
            } else if (csvColumnConfig[column.index + modifier].subColumns.length > 0 && csvColumnConfig[column.index].subColumns.length === 0) {
                /* Swap Subquery/Aggregate group with Primary field */
                this._swapFieldGroupWithPrimaryField(component, column, modifier, csvColumnConfig);
            } else if (csvColumnConfig[column.index].subColumns.length > 0 && csvColumnConfig[column.index + modifier].subColumns.length > 0) {
                /* Swap Subquery/Aggregate group with Subquery/Aggregate group */
                this._updateIndices(component, csvColumnConfig, 0, 0);
            } else {
                /* Swap Primary fields */
                csvColumnConfig[column.index].columnNum -= modifier;
                csvColumnConfig[column.index + modifier].columnNum += modifier;
                component.set('v.csvColumnConfig', csvColumnConfig);
            }
        }
    },

    /* Swap Primary field with Subquery/Aggregate group */
    _swapPrimaryFieldWithFieldGroup: function(component, column, modifier, csvColumnConfig) {
        var columnNumDiff = (csvColumnConfig[column.index].subColumns.length * modifier);
        if (csvColumnConfig[column.index].apiName === 'Subquery' || csvColumnConfig[column.index].apiName === 'Secondary') {
            columnNumDiff = columnNumDiff * csvColumnConfig[column.index].numResults;
        }
        csvColumnConfig[column.index + modifier].columnNum += columnNumDiff;
        csvColumnConfig[column.index].columnNum -= modifier;

         for (var j in csvColumnConfig[column.index].subColumns) {
            csvColumnConfig[column.index].subColumns[j].columnNum -= modifier
            csvColumnConfig[column.index].subColumns[j].parentIndex = csvColumnConfig[column.index].index;
        }
        component.set('v.csvColumnConfig', csvColumnConfig);
    },

    /* Swap Subquery/Aggregate group with Primary field */
    _swapFieldGroupWithPrimaryField: function(component, column, modifier, csvColumnConfig) {
        var columnNumDiff = csvColumnConfig[column.index + modifier].subColumns.length * modifier;
        if (column.apiName === 'Subquery') {
            columnNumDiff = columnNumDiff * column.numResults;
        }
        csvColumnConfig[column.index + modifier].columnNum += modifier;
        csvColumnConfig[column.index].columnNum -= columnNumDiff;

        for (var j = 0; j < csvColumnConfig[column.index + modifier].subColumns.length; j++) {
            csvColumnConfig[column.index + modifier].subColumns[j].columnNum
                = csvColumnConfig[column.index + modifier].columnNum + j;
            csvColumnConfig[column.index + modifier].subColumns[j].parentIndex
                = csvColumnConfig[column.index + modifier].index;
        }
        component.set('v.csvColumnConfig', csvColumnConfig);
    },

    handleFieldChange: function(component, column) {
        var csvColumnConfig = component.get('v.csvColumnConfig');
        var defaultCSVConfig = JSON.parse(JSON.stringify(component.get('v.defaultCSVConfig')));
        var found = false;

        if (column.field === '--SELECT--') {
            this._handleSelectPlaceHolder(component, column);
            found = true;
        } else {
            for (var i in defaultCSVConfig) {
                if (found) {
                    break;

                } else if (defaultCSVConfig[i].queryId === column.queryId) {

                    if (column.parentIndex) {
                        // Change subColumn field
                        for (var j in defaultCSVConfig[i].subColumns) {
                            var subCol = defaultCSVConfig[i].subColumns[j];
                            if (subCol.field === column.field) {
                                Object.assign(csvColumnConfig[column.parentIndex].subColumns[column.index], subCol);
                                found = true;
                                break;
                            }
                        }
                    } else if (defaultCSVConfig[i].field === column.field) {
                        // Found match for the field (not subcolumn)
                        var currentColumnNum = parseInt(column.columnNum);
                        var currentColumnIndex = parseInt(column.index);
                        csvColumnConfig[column.index] = {};
                        Object.assign(csvColumnConfig[column.index], defaultCSVConfig[i]);
                        csvColumnConfig[column.index].columnNum = currentColumnNum;
                        csvColumnConfig[column.index].index = currentColumnIndex;
                        found = true;
                        break;
                    }
                }
            }
            if (found) {
                this._updateIndices(component, csvColumnConfig, column.index, column.columnNum);
            }
        }
    },

    _handleSelectPlaceHolder: function(component, column) {
        var csvColumnConfig = component.get('v.csvColumnConfig');
        var col = {
            index: column.index,
            parentIndex: column.parentIndex,
            columnNum: column.columnNum,
            numResults: '',
            selectIndex: column.selectIndex,
            altValue: '',
            apiName: '',
            field: '--SELECT--',
            formatting: '',
            groupingValue: column.groupingValue,
            key: '',
            label: '',
            queryId: column.queryId,
            selectSource: column.selectSource,
            subColumns: []
        };
        if (column.parentIndex) {
            Object.assign(csvColumnConfig[column.parentIndex].subColumns[column.index], col);
            component.set('v.csvColumnConfig', csvColumnConfig);
        } else {
            Object.assign(csvColumnConfig[column.index], col);
            this._updateIndices(component, csvColumnConfig, column.index, column.columnNum);
        }
    },

    changeNumberOfSubColumnResults: function(component, column, action) {
        var parentColumn = JSON.parse(JSON.stringify(column));
        if (!parentColumn
              || parentColumn === undefined
              || !parentColumn.subColumns
              || parentColumn.subColumns === undefined
              || !parentColumn.selectSource
              || parentColumn.selectSource === undefined) {
            return;
        }

        var numSubColumns = parseInt(parentColumn.numResults);

        var src = parentColumn.selectSource.toLowerCase();
        var csvColumnConfig = component.get('v.csvColumnConfig');

        if (src.indexOf('subquery') !== -1 || src.indexOf('secondary') !== -1) {
            // Handle the subquery results
            // Just update the indices, we will create the columns when the template is saved.
            this._updateIndices(component, csvColumnConfig, column.index, column.columnNum);
        } else if (src.indexOf('aggregate') !== -1) {
            // Handle the aggregate results
            // create the columns and update the indices
            this._handleAggregate(component, parentColumn, csvColumnConfig, action);
        }
    },

    _handleAggregate: function(component, parentColumn, csvColumnConfig, action) {
        // Get the defaultCSVConfig's subcolumns
        var defaultSubColumns = this._getDefaultSubColumns(component, parentColumn);

        if (action === 'addResult') {
            // Add the default subcolumns to the existing subcolumn's array
            for (var i in defaultSubColumns) {
                var defaultSubColumn = {};
                Object.assign(defaultSubColumn, defaultSubColumns[i]);
                parentColumn.subColumns.push(defaultSubColumn);
            }
        } else {
            // Build map of the default subcolumns
            var defaultSubColumnMap = {};
            for (var i in defaultSubColumns) {
                var defaultSubColumn = {};
                Object.assign(defaultSubColumn, defaultSubColumns[i]);
                defaultSubColumnMap[defaultSubColumn.key] = defaultSubColumn;
            }

            var parentClone = {};
            Object.assign(parentClone, parentColumn);
            var removedMap = {};

            /*
                Iterate over the current subcolumns starting from the end of the list.
                If the subcolumn's key is found in the defaultSubColumnMap but not found
                in the removedMap, then remove the subColumn from the existing list of subcolumns.
            */

            for (var i = parentClone.subColumns.length-1; i >= 0; i--) {
                var subCol = parentClone.subColumns[i];

                if (defaultSubColumnMap[subCol.key] && defaultSubColumnMap[subCol.key] !== undefined) {
                    // Subcolumn exists in the default subcolumn config as it should.
                    if (removedMap[subCol.key] === false || removedMap[subCol.key] === undefined) {
                        removedMap[subCol.key] = true;
                        parentColumn.subColumns.splice(i, 1);
                    }
                }
            }
        }

        Object.assign(csvColumnConfig[parentColumn.index], parentColumn);
        this._updateIndices(component, csvColumnConfig, parentColumn.index, parentColumn.columnNum);
    },

    _getDefaultSubColumns: function(component, parentColumn) {
        var defaultCSVConfig = component.get('v.defaultCSVConfig');
        var defaultSubColumns = [];

        for (var i in defaultCSVConfig) {
            var defaultParentColumn = defaultCSVConfig[i];
            if (parentColumn.key === defaultParentColumn.key) {
                // Found the parent column
                defaultSubColumns = JSON.parse(JSON.stringify(defaultParentColumn.subColumns));
                break;
            }
        }

        return defaultSubColumns;
    },

    _updateIndices: function(component, csvColumnConfig, startIndex, startColumn) {
        var columnNumber = startColumn;
        /*
            Iterate over the primary query column configs, subquery parent column configs,
            and aggregate parent column configs
        */
        for (var i = startIndex; i < csvColumnConfig.length; i++) {
            csvColumnConfig[i].index = i; // Index of the primary query column, subquery grouping, or aggregate grouping index
            csvColumnConfig[i].columnNum = columnNumber; // Actual column number in csv
            if (!csvColumnConfig[i].subColumns
                  || csvColumnConfig[i].subColumns === undefined
                  || csvColumnConfig[i].subColumns.length == 0
                  || !csvColumnConfig[i].numResults) {
                columnNumber++;

            } else if (csvColumnConfig[i].apiName === 'Aggregate' && csvColumnConfig[i].subColumns) {
                for (var j = 0; j < csvColumnConfig[i].subColumns.length; j++) {
                    csvColumnConfig[i].subColumns[j].index = j; // Sub column index
                    csvColumnConfig[i].subColumns[j].parentIndex = i; // Parent grouping's index
                    csvColumnConfig[i].subColumns[j].columnNum = columnNumber; // Actual column number in csv
                    columnNumber++;
                }

            } else if (csvColumnConfig[i].subColumns
                    && (csvColumnConfig[i].apiName === 'Subquery' || csvColumnConfig[i].apiName === 'Secondary')) {
                // It's a subquery or aggregate parent column config
                var numResults = parseInt(csvColumnConfig[i].numResults);
                var numSubColumns = parseInt(csvColumnConfig[i].subColumns.length);
                var groupZeroSubqueryColumns = [];

                // Iterate over the child column configs
                for (var j = 0; j < csvColumnConfig[i].subColumns.length; j++) {
                    if (!csvColumnConfig[i].subColumns[j].groupingValue
                        || csvColumnConfig[i].subColumns[j].groupingValue === undefined
                        || parseInt(csvColumnConfig[i].subColumns[j].groupingValue) > 0) {
                        // We will complete the config for the subquery columns when the template is saved
                      break;
                    }
                    csvColumnConfig[i].subColumns[j].index = j; // Sub column index
                    csvColumnConfig[i].subColumns[j].parentIndex = i; // Parent grouping's index
                    csvColumnConfig[i].subColumns[j].columnNum = columnNumber; // Actual column number in csv
                    columnNumber++;

                    if (csvColumnConfig[i].subColumns[j].groupingValue
                          && csvColumnConfig[i].subColumns[j].groupingValue !== undefined
                          && parseInt(csvColumnConfig[i].subColumns[j].groupingValue) === 0) {
                        var subColCopy = JSON.parse(JSON.stringify(csvColumnConfig[i].subColumns[j]));
                        groupZeroSubqueryColumns.push(subColCopy);
                    }
                }

                var expectedNumSubColumns = groupZeroSubqueryColumns.length * numResults;
                var diff = parseInt(expectedNumSubColumns) - numSubColumns;
                if (parseInt(diff) > 0) {
                    // Update the columnNumber for the next column such that the current number of results
                    // for the current subcolumns is accounted for.
                    columnNumber += diff;
                }
            }
        }
        component.set('v.csvColumnConfig', csvColumnConfig);
    }
})