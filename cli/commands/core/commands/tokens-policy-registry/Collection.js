const setPolicy = require("./SetPolicyCommand");
const setPolicyWithId = require("./SetPolicyWithIdCommand");
const getPolicy = require("./GetPolicyCommand");
const CommandsCollection = require("../CommandsCollection");


/**
 * @fileoverview Initialize all commands that are related to the Tokens polcy registry
 * @namespace coreCommands Smart contracts related commands
 */
class Collection extends CommandsCollection {
    /**
     * Initialize all commands
     * @constructor
     * @public
     */
    constructor() {
        super();
        this.commands = [
            new setPolicy(),
            new getPolicy(),
            new setPolicyWithId(),
        ];
    }
}

module.exports = new Collection();