// import React from 'react';
import { withTheme, default as Form } from '@rjsf/core';


import { Theme as Bootstrap3Theme } from '@rjsf/core';

import { ArrayFieldTemplateProps, DescriptionFieldProps, RJSFSchema } from '@rjsf/utils';

import firewallRulesRawSchema from './schemas/resolved.schema.json';
import firewallRulesUISchema from './schemas/UISchema.json';
import Ajv from 'ajv';
import ajvErrors from 'ajv-errors';

import validator from '@rjsf/validator-ajv8';
// import './App.css'; // Assuming your custom CSS is here
import './modal.css';

import React, { useState } from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faCopy, faPaste, faEye, faBook } from '@fortawesome/free-solid-svg-icons';
// import CustomFieldTemplate from './CustomFieldTemplate.tsx';
import Modal from 'react-bootstrap/Modal';
import Button from 'react-bootstrap/Button';
// import { toErrorList } from '@rjsf/core/lib/validate';
// import { Tooltip, OverlayTrigger } from 'react-bootstrap';

import 'bootstrap/dist/css/bootstrap.min.css';

import Tooltip from '@mui/material/Tooltip';
import IconButton from '@mui/material/IconButton';
import HelpOutlineIcon from '@mui/icons-material/HelpOutline';

// import { customArray } from './customArray.js';

// import { ArrayFieldTemplateProps } from '@rjsf/utils';

// Initialize AJV with options suitable for your needs
const ajv = new Ajv({ allErrors: true, useDefaults: true });
ajvErrors(ajv); // Optional: Use ajv-errors for better error messages

const schema = {
  type: "object",
  properties: {
    firewall_rules: firewallRulesRawSchema
  }
}


const uiSchema = {
  // 'firewall_rules': firewallRulesUISchema,
  'ui:submitButtonOptions': {
    norender: true
  },
  'firewall_rules': {
    // 'ui:ArrayFieldItemTemplate': ArrayFieldItemTemplate,
    'ui:ArrayFieldTemplate': ArrayFieldTemplate,
    "ui:options": {
      "copyable": true
    },
    'items': {
      'direction': {
        'ui:DescriptionFieldTemplate': DescriptionFieldTemplate
      }
    }
  }
}

function ArrayFieldTemplate(props) {
  const { children, className, onAddClick, canAdd } = props;
  return (
    <div>
      {props.items.map((element) => element.children)}
      {props.canAdd && <button type='button' onClick={props.onAddClick} 
      // class='btn btn-info btn-add col-xs-12' 
      className={className}
      title='Add'>Add </button>}
      {/* {props.canDe && <button type='button' onClick={props.onAddClick}></button>} */}
    </div>
  );
}

function ArrayFieldItemTemplate(props) {
  const { children, className } = props;
  return (
    <>
      <div className={className} >{children}</div>
      <div class="col-xs-3 array-item-toolbox">
        <div class="btn-group" style="display: flex; justify-content: space-around;">
          <button type="button" class="btn btn-default array-item-copy" title="Copy" style="flex: 1 1 0%; padding-left: 6px; padding-right: 6px; font-weight: bold;">
            <i class="glyphicon glyphicon-copy"></i>
          </button><button type="button" class="btn btn-danger array-item-remove" title="Remove" style="flex: 1 1 0%; padding-left: 6px; padding-right: 6px; font-weight: bold;">
            <i class='glyphicon glyphicon-remove'></i>
          </button>
        </div>
      </div>
    </>
  );
}

function DescriptionFieldTemplate(props) {
  const { description, id } = props;
  return (
    <Tooltip title={description} >
      <IconButton size="small">
        <HelpOutlineIcon />
      </IconButton>
    </Tooltip>
  );
}


// Define a function to handle form submission
const onSubmit = ({ formData }, e) => console.log("Data submitted: ", formData);

function App() {
  const [formData, setFormData] = useState({}); // Initial form data
  const [showModal, setShowModal] = useState(false);

  const resetFormData = () => {
    setFormData({}); // Reset form data to initial state, adjust { } as needed
    console.log('Form data has been reset');
  };

  const copyJsonToClipboard = (formData) => {
    const dataStr = JSON.stringify(formData.firewall_rules, null, 2);
    navigator.clipboard.writeText(dataStr).then(() => {
      console.log('FormData copied to clipboard');
    }, (err) => {
      console.error('Could not copy text: ', err);
    });
  };

  const loadJsonFromClipboard = async () => {
    try {
      const text = await navigator.clipboard.readText(); // Read text from clipboard
      const formData = JSON.parse(text); // Attempt to parse it as JSON
      setFormData({ firewall_rules: formData }); // Update your form's state
      console.log('FormData loaded from clipboard');
    } catch (err) {
      console.error('Failed to load JSON from clipboard:', err);
    }
  };

  const handleFormDataChange = ({ formData }) => {
    setFormData(formData);
  };
  const toggleModal = () => {
    // console.log("Toggle clicked")
    console.log("Toggling modal from", showModal, "to", !showModal);
    setShowModal(!showModal)
  };
  return (
    <div className="App container mt-5">

      <center>
        <button onClick={() => loadJsonFromClipboard(formData)} className="btn btn-info btn-lg" title="Copy to Clipboard">
          <FontAwesomeIcon icon={faPaste} /> Load FormData
        </button>
        <button onClick={() => copyJsonToClipboard(formData)} className="btn btn-info btn-lg" title="Copy to Clipboard">
          <FontAwesomeIcon icon={faCopy} /> Copy FormData
        </button>
        <button onClick={toggleModal} className="btn btn-info btn-lg" title="View JSON">
          <FontAwesomeIcon icon={faEye} /> View JSON
        </button>
        <button onClick={() => window.open(document.location.pathname + "./documentation", "_blank")} className="btn btn-info btn-lg" title="View Documentation">
          <FontAwesomeIcon icon={faBook} /> View Documentation
        </button>
        <button onClick={resetFormData} className="btn btn-danger btn-lg" title="Reset Form">
          Reset Form
        </button>
      </center>


      {/* Modal */}
      {showModal && (
        <div id="myModal" className="modal fade in" role="dialog" style={{ display: 'block' }}>
          <div className="modal-dialog">
            {/* Modal content*/}
            <div className="modal-content">
              <div className="modal-header">
                <button type="button" className="close" onClick={toggleModal}>&times;</button>
                <h4 className="modal-title">Form Data JSON</h4>
              </div>
              <div className="modal-body">
                <pre>{JSON.stringify(formData.firewall_rules, null, 2)}</pre>
              </div>
              <div className="modal-footer">
                <button type="button" className="btn btn-default" onClick={() => copyJsonToClipboard(formData)}>Copy JSON</button>
                <button type="button" className="btn btn-default" onClick={toggleModal}>Close</button>
              </div>
            </div>
          </div>
        </div>
      )}
      {showModal && <div className="modal-backdrop fade in"></div>}


      {/* "ui:ArrayFieldTemplate": "ArrayFieldTemplate", */}
      {/* "ui:DescriptionFieldTemplate": "DescriptionFieldTemplate", */}
      <Form
        schema={schema}
        uiSchema={uiSchema}
        onSubmit={onSubmit}
        formData={formData}
        onChange={handleFormDataChange}
        liveValidate
        validator={validator}
      // templates={{ DescriptionFieldTemplate }}
      // fields={{ ArrayFieldTemplate }}
      />
    </div>
  );
}

export default App;
